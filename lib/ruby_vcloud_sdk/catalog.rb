require_relative "vdc"
require_relative "session"
require_relative "infrastructure"
require_relative "catalog_item"

module VCloudSdk
  class Catalog
    include Infrastructure

    attr_reader :name

    def initialize(session, catalog_link)
      @session = session
      @catalog_link = catalog_link
      @name = @catalog_link.name
    end

    def id
      @catalog_link.href_id
    end

    def items
      admin_xml.catalog_items.map do |item|
        VCloudSdk::CatalogItem.new(@session, item)
      end
    end

    def delete_all_catalog_items
      items.each do |catalog_item|
        Config.logger.info "Deleting catalog item \"#{catalog_item.name}\""
        connection.delete(catalog_item.remove_link)
      end
    end

    def upload_vapp_template(
        vdc_name,
        template_name,
        directory,
        storage_profile_name = nil)
      if item_exists?(template_name)
        fail "vApp template '#{template_name}' already exists in catalog #{name}"
      end

      vdc = find_vdc_by_name vdc_name

      storage_profile = vdc.storage_profile_xml_node storage_profile_name

      Config.logger.info "Uploading vApp #{template_name} to #{vdc.name}"
      vapp_template = upload_vapp_template_params(template_name, vdc, storage_profile)

      vapp_template = upload_vapp_files(vapp_template, ovf_directory(directory))

      validate_vapp_template_tasks vapp_template

      Config.logger.info %Q{
        Template #{template_name} uploaded, adding to catalog #{name}.
      }
      add_item(vapp_template)
    end

    def upload_media(
        vdc_name,
        media_name,
        file,
        storage_profile_name = nil,
        image_type = "iso")

      if item_exists?(media_name)
        fail "Catalog Item '#{media_name}' already exists in catalog #{name}"
      end

      Config.logger.info %Q{
         Uploading file #{file}
         as media #{media_name} of type #{image_type}
         to catalog #{name}, storage profile #{storage_profile_name}, vdc #{vdc_name}
      }

      media_file = file.is_a?(String) ? File.new(file, "rb") : file

      vdc = find_vdc_by_name vdc_name

      storage_profile = vdc.storage_profile_xml_node storage_profile_name

      media = upload_media_params media_name, vdc, media_file, image_type, storage_profile

      media = upload_media_file media, media_file

      add_item(media)
    end

    def add_item(item)
      catalog_item = create_catalog_item_payload(item)
      Config.logger.info "Adding #{catalog_item.name} to catalog #{name}"
      connection.post(admin_xml.add_item_link,
                      catalog_item,
                      Xml::ADMIN_MEDIA_TYPE[:CATALOG_ITEM])
      Config.logger.info %Q{
        catalog_item #{catalog_item.name} added to catalog #{name}:
        #{catalog_item.to_s}
      }
      catalog_item
    end

    def find_vapp_template_by_name(name)
      find_item(name, Xml::MEDIA_TYPE[:VAPP_TEMPLATE])
    end

    def instantiate_vapp_template(template_name, vdc_name, vapp_name,
        description = nil, disk_locality = nil)

      instantiate_vapp_params = create_instantiate_vapp_params(
          template_name, vapp_name, description, disk_locality)

      vdc = find_vdc_by_name vdc_name

      vapp = connection.post(vdc.instantiate_vapp_template_link,
                             instantiate_vapp_params)
      vapp.running_tasks.each do |task|
        begin
          monitor_task(task, @session.time_limit[:instantiate_vapp_template])
        rescue ApiError => e
          Config.logger.error(e, "Instantiate vApp template #{vapp_name} " +
              "failed. Task #{task.operation} did not complete successfully.")
          raise e
        end
      end

      vdc = find_vdc_by_name vdc_name # Refresh information about vdc
      vdc.find_vapp_by_name vapp_name
    end

    # Find catalog item from catalog by name and type.
    # If item_type is set to nil, returns catalog item as long as its name match.
    # Raises an exception if catalog is not found.
    # Raises ObjectNotFoundError if an item matching the name and type is not found.
    # Otherwise, returns the catalog item.
    def find_item(name, item_type = nil)
      fail ObjectNotFoundError, "Catalog item name cannot be nil" unless name

      items.each do |catalog_item|
        return catalog_item if catalog_item.name == name &&
            (!item_type || catalog_item.type == item_type)
      end

      fail ObjectNotFoundError, "Catalog Item '#{name}' is not found"
    end

    def item_exists?(name, item_type = nil)
      items.any? do |item|
        item.name == name &&
          (!item_type || item.type == item_type)
      end
    end

    private

    def upload_vapp_template_params(template_name, vdc, storage_profile)
      upload_params = Xml::WrapperFactory.create_instance(
        "UploadVAppTemplateParams")
      upload_params.name = template_name
      upload_params.storage_profile = storage_profile
      connection.post(vdc.upload_link, upload_params)
    end

    def ovf_directory(directory)
      # if directory behaves like an OVFDirectory, then use it
      is_ovf_directory = [:ovf_file, :ovf_file_path, :vmdk_file, :vmdk_file_path]
        .reduce(true) do |present, name|
        present && directory.respond_to?(name)
      end

      if is_ovf_directory
        directory
      else
        OVFDirectory.new(directory)
      end
    end

    def admin_xml
      admin_catalog_link = "/api/admin/catalog/#{id}"
      admin_catalog = connection.get(admin_catalog_link)

      unless admin_catalog
        fail ObjectNotFoundError,
             "Catalog #{name} of link #{admin_catalog_link} not available."
      end

      admin_catalog
    end

    def create_catalog_item_payload(item)
      catalog_item = Xml::WrapperFactory.create_instance(Xml::XML_TYPE[:CATALOGITEM])
      catalog_item.name = item.name
      catalog_item.entity = item
      catalog_item
    end

    def validate_vapp_template_tasks(vapp_template)
      err_tasks = connection.get(vapp_template).tasks.select do |t|
        t.status != Xml::TASK_STATUS[:SUCCESS]
      end
      unless err_tasks.empty?

        Config.logger.error %Q{
          Error uploading vApp template.
          Non-successful tasks:
          #{err_tasks}
        }
        fail CloudError, "Error uploading vApp template"
      end
    end

    def upload_vapp_files(
        vapp_template,
        ovf_directory,
        tries = @session.retries[:upload_vapp_files])
      tries.times do |try|
        current_vapp_template = connection.get(vapp_template)
        if !current_vapp_template.files || current_vapp_template.files.empty?
          Config.logger.info %Q{
            #{current_vapp_template.name} has tasks in progress...
            Waiting until done...
          }
          current_vapp_template.running_tasks.each do |task|
            monitor_task(task,
                         @session.time_limit[:process_descriptor_vapp_template])
          end

          return current_vapp_template
        end

        Config.logger.debug "vapp files left to upload #{current_vapp_template.files}."
        Config.logger.debug %Q{
          vapp incomplete files left to upload:
          #{current_vapp_template.incomplete_files}
        }

        current_vapp_template.incomplete_files.each do |f|
          # switch on extension
          case f.name.split(".")[-1].downcase
          when "ovf"
            Config.logger.info %Q{
              Uploading OVF file:
              #{ovf_directory.ovf_file_path} for #{vapp_template.name}
            }
            connection.put(f.upload_link, ovf_directory.ovf_file.read,
                           Xml::MEDIA_TYPE[:OVF])
          when "vmdk"
            Config.logger.info %Q{
              Uploading VMDK file:
              #{ovf_directory.vmdk_file_path(f.name)} for #{vapp_template.name}
            }
            connection.put_file(f.upload_link,
                                ovf_directory.vmdk_file(f.name))
          end
        end
        # Repeat
        sleep 2**try
      end

      fail ApiTimeoutError,
           %Q{
             Unable to finish uploading vApp after #{tries} tries.
             current_vapp_template.files:
             #{current_vapp_template.files}
           }
    end

    def retrieve_vapp_template_xml_node(template_name)
      vapp_template = find_vapp_template_by_name(template_name)
      unless vapp_template
        fail ObjectNotFoundError, "vapp_template #{template_name}" +
            "cannot be found in catalog #{@name}."
      end

      connection.get(vapp_template.href)
    end

    def create_instantiate_vapp_params(template_name,
        vapp_name, description, disk_locality)

      source_vapp_template = retrieve_vapp_template_xml_node(template_name)

      instantiate_vapp_params = Xml::WrapperFactory.create_instance(
          "InstantiateVAppTemplateParams")
      instantiate_vapp_params.name = vapp_name
      instantiate_vapp_params.description = description
      instantiate_vapp_params.source = source_vapp_template
      instantiate_vapp_params.all_eulas_accepted = true
      instantiate_vapp_params.linked_clone = false
      instantiate_vapp_params.set_locality = locality_spec(
          source_vapp_template, disk_locality)

      instantiate_vapp_params
    end

    def locality_spec(vapp_template, disk_locality)
      disk_locality ||= []
      locality = {}
      disk_locality.each do |disk|
        current_disk = connection.get(disk)
        unless current_disk
          Config.logger.info "Disk #{disk.name} no longer exists."
          next
        end
        vapp_template.vms.each do |vm|
          locality[vm] = current_disk
        end
      end
      locality
    end

    def upload_media_params(media_name, vdc, media_file, image_type, storage_profile)
      upload_params = Xml::WrapperFactory.create_instance("Media")
      upload_params.name = media_name
      upload_params.size = media_file.stat.size
      upload_params.image_type = image_type
      upload_params.storage_profile = storage_profile

      connection.post(vdc.upload_media_link, upload_params)
    end

    def upload_media_file(media, media_file)
      incomplete_file = media.incomplete_files.pop
      connection.put_file(incomplete_file.upload_link, media_file)
      connection.get(media)
    end
  end
end
