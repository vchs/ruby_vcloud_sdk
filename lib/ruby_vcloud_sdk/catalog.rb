require_relative "vdc"
require_relative "session"
require_relative "infrastructure"

module VCloudSdk

  class Catalog
    include Infrastructure

    attr_reader :name

    def initialize(session, catalog_xml_obj)
      @session = session
      @catalog_xml_obj = catalog_xml_obj
      @name = catalog_xml_obj.name
    end

    def id
      @catalog_xml_obj.href_id
    end

    def items
      admin_xml.catalog_items
    end

    def delete_all_catalog_items
      items.each do |catalog_item_xml_obj|
        catalog_item = connection.get("/api/catalogItem/#{catalog_item_xml_obj.href_id}")
        Config.logger.info "Deleting catalog item \"#{catalog_item.name}\""
        connection.delete(catalog_item.remove_link)
      end
    end

    def upload_vapp_template(vdc_name, template_name, directory)
      fail "OVF directory is nil" if directory.nil?
      if item_exists?(template_name)
        fail "vApp template '#{template_name}' already exists in catalog #{name}"
      end

      vdc = find_vdc_by_name vdc_name

      Config.logger.info "Uploading vApp #{template_name} to #{vdc.name}"
      vapp_template = upload_vapp_template_params(template_name, vdc)

      vapp_template = upload_vapp_files(vapp_template, ovf_directory(directory))

      validate_vapp_template_tasks vapp_template

      Config.logger.info %Q{
        Template #{template_name} uploaded, adding to catalog #{name}.
      }
      add_item(vapp_template)
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

    private

    def item_exists?(name)
      items.each do |item|
        if item.name == name
          return true
        end
      end

      false
    end

    def upload_vapp_template_params(template_name, vdc)
      upload_params = Xml::WrapperFactory.create_instance(
        "UploadVAppTemplateParams")
      upload_params.name = template_name
      vapp_template = connection.post(vdc.upload_link, upload_params)
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
  end
end