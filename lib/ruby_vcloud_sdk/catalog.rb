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

    def catalog_items
      connection.get("/api/admin/catalog/#{id}").catalog_items
    end

    def delete_all_catalog_items
      catalog_items.each do |catalog_item_xml_obj|
        catalog_item = connection.get("/api/catalogItem/#{catalog_item_xml_obj.href_id}")
        Config.logger.info "Deleting catalog item \"#{catalog_item.name}\""
        connection.delete(catalog_item.remove_link)
      end
    end

    def upload_vapp_template(vdc_name, vapp_name, directory)
      fail "OVF directory is not defined" if directory.nil? || directory.empty?
      vdc = find_vdc_by_name vdc_name
      Config.logger.info "Uploading VM #{vapp_name} to #{vdc.name}"
      # if directory behaves like an OVFDirectory, then use it
      is_ovf_directory = [:ovf_file, :ovf_file_path, :vmdk_file,
                          :vmdk_file_path].reduce(true) do |present, name|
        present && directory.respond_to?(name)
      end
      ovf_directory = is_ovf_directory ? directory :
        OVFDirectory.new(directory)
      upload_params = Xml::WrapperFactory.create_instance(
        "UploadVAppTemplateParams")
      upload_params.name = vapp_name
      vapp_template = connection.post(vdc.upload_link, upload_params)
      vapp_template = upload_vapp_files(vapp_template, ovf_directory)
      fail ObjectNotFoundError, "Error uploading vApp template" unless
        vapp_template
      Config.logger.info %Q{
        #{vapp_template.name} has tasks in progress...
        Waiting until done...
      }
      vapp_template.running_tasks.each do |task|
        monitor_task(task,
                     @session.time_limit[:process_descriptor_vapp_template])
      end
      err_tasks = @connection.get(vapp_template).tasks.select do
        |t| t.status != Xml::TASK_STATUS[:SUCCESS]
      end
      unless err_tasks.empty?
        Config.logger.error %Q{
          Error uploading vApp template.
          Non-successful tasks:
          #{err_tasks}
        }
        fail CloudError, "Error uploading vApp template"
      end
      Config.logger.info %Q{
        vApp #{vapp_name} uploaded, adding to catalog #{name}.
      }
      catalog_item = add_catalog_item(vapp_template, name)
      Config.logger.info %Q{
        vApp #{vapp_name} added to catalog #{name} #{catalog_item.to_s}
      }
      catalog_item
    end

    private

    def upload_vapp_files(vapp, ovf_directory,
      tries = @session.retries[:upload_vapp_files])
      try = 0
      tries.times do
        current_vapp = @connection.get(vapp)
        return current_vapp if !current_vapp.files || current_vapp.files.empty?

        Config.logger.debug "vapp files left to upload #{current_vapp.files}."
        Config.logger.debug %Q{
          vapp incomplete files left to upload:
          #{current_vapp.incomplete_files}
        }

        current_vapp.incomplete_files.each do |f|
          # switch on extension
          case f.name.split(".")[-1].downcase
          when "ovf"
            Config.logger.info %Q{
              Uploading OVF file:
              #{ovf_directory.ovf_file_path} for #{vapp.name}
            }
            @connection.put(f.upload_link, ovf_directory.ovf_file.read,
                            Xml::MEDIA_TYPE[:OVF])
          when "vmdk"
            Config.logger.info %Q{
              Uploading VMDK file:
              #{ovf_directory.vmdk_file_path(f.name)} for #{vapp.name}
            }
            @connection.put_file(f.upload_link,
                                 ovf_directory.vmdk_file(f.name))
          end
        end
        # Repeat
        try += 1
        sleep 2**try
      end

      fail ApiTimeoutError, "Unable to finish uploading vApp after " +
        "#{tries} tries #{current_vapp.files}."
    end

    def add_catalog_item(item, catalog_name)
      org = @session.org
      catalog_link = org.catalog_link(catalog_name)
      unless catalog_link
        fail ArgumentError,
             "Error adding #{item.name}, catalog #{catalog_name} not found."
      end
      catalog = @connection.get(catalog_link)
      fail ObjectNotFoundError, "Error adding #{item.name}, catalog " +
        "#{catalog_name} not available." unless catalog
      catalog_item = Xml::WrapperFactory.create_instance("CatalogItem")
      catalog_item.name = item.name
      catalog_item.entity = item
      Config.logger.info "Adding #{catalog_item.name} to catalog #{catalog_name}"
      @connection.post(catalog.add_item_link, catalog_item,
                       Xml::ADMIN_MEDIA_TYPE[:CATALOG_ITEM])
    end

  end
end
