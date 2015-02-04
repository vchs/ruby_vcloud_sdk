require "forwardable"
require "uri"
require_relative "vdc_storage_profile"
require_relative "vapp"
require_relative "infrastructure"
require_relative "resources"
require_relative "cpu"
require_relative "disk"
require_relative "memory"
require_relative "network"
require_relative "edge_gateway"

module VCloudSdk
  class VDC
    include Infrastructure

    extend Forwardable
    def_delegators :entity_xml,
                   :name, :upload_link, :upload_media_link,
                   :instantiate_ovf_link,
                   :instantiate_vapp_template_link

    public :find_network_by_name, :network_exists?

    def initialize(session, link)
      @session = session
      @link = link
    end

    def storage_profiles
      storage_profile_records.map do |storage_profile|
        VCloudSdk::VdcStorageProfile.new(storage_profile)
      end
    end

    def list_storage_profiles
      storage_profile_records.map do |storage_profile|
        storage_profile.name
      end
    end

    def find_storage_profile_by_name(name)
      storage_profile_records.each do |storage_profile|
        if storage_profile.name == name
          return VCloudSdk::VdcStorageProfile.new(storage_profile)
        end
      end

      fail ObjectNotFoundError, "Storage profile '#{name}' is not found"
    end

    def storage_profile_exists?(name)
      storage_profile_records.any? do |storage_profile|
        storage_profile.name == name
      end
    end

    def vapps
      entity_xml.vapps.map do |vapp_link|
        VCloudSdk::VApp.new(@session, vapp_link)
      end
    end

    def list_vapps
      entity_xml.vapps.map do |vapp_link|
        vapp_link.name
      end
    end

    def find_vapp_by_name(name)
      entity_xml.vapps.each do |vapp_link|
        if vapp_link.name == name
          return VCloudSdk::VApp.new(@session, vapp_link)
        end
      end

      fail ObjectNotFoundError, "VApp '#{name}' is not found"
    end

    def vapp_exists?(name)
      entity_xml.vapps.any? do |vapp|
        vapp.name == name
      end
    end

    def resources
      cpu = VCloudSdk::CPU.new(entity_xml.available_cpu_cores)
      memory = VCloudSdk::Memory.new(entity_xml.available_memory_mb)
      VCloudSdk::Resources.new(cpu, memory)
    end

    def networks
      @session.org.networks.map do |network_link|
        VCloudSdk::Network.new(@session, network_link)
      end
    end

    def list_networks
      @session.org.networks.map do |network_link|
        network_link.name
      end
    end

    def edge_gateways
      connection
        .get(entity_xml.edge_gateways_link)
        .edge_gateway_records
        .map do |edge_gateway_link|
        VCloudSdk::EdgeGateway.new(@session, edge_gateway_link.href)
      end
    end

    def disks
      entity_xml.disks.map do |disk_link|
        VCloudSdk::Disk.new(@session, disk_link)
      end
    end

    def list_disks
      entity_xml.disks.map do |disk_link|
        disk_link.name
      end
    end

    def find_disks_by_name(name)
      disks = entity_xml
                .disks
                .select { |disk_link| disk_link.name == name }
                .map { |disk_link| VCloudSdk::Disk.new(@session, disk_link.href) }

      if disks.empty?
        fail ObjectNotFoundError, "Disk '#{name}' is not found"
      end

      disks
    end

    def disk_exists?(name)
      list_disks.any? do |disk_name|
        disk_name == name
      end
    end

    def create_disk(
          name,
          capacity,
          vm = nil,
          bus_type = "scsi",
          bus_sub_type = "lsilogic")

      fail(CloudError,
           "Invalid size in MB #{capacity}") if capacity <= 0

      bus_type = Xml::BUS_TYPE_NAMES[bus_type.downcase]
      fail(CloudError,
           "Invalid bus type!") unless bus_type

      bus_sub_type = Xml::BUS_SUB_TYPE_NAMES[bus_sub_type.downcase]
      fail(CloudError,
           "Invalid bus sub type!") unless bus_sub_type

      Config
        .logger
        .info "Creating independent disk #{name} of #{capacity}MB."

      disk = connection.post(entity_xml.add_disk_link,
                             disk_create_params(name, capacity, bus_type, bus_sub_type, vm),
                             Xml::MEDIA_TYPE[:DISK_CREATE_PARAMS])

      wait_for_running_tasks(disk, "Disk #{name}")

      VCloudSdk::Disk.new(@session, disk.href)
    end

    def delete_disk_by_name(name)
      disks = find_disks_by_name(name)
      fail CloudError,
           "#{disks.size} disks with name #{name} were found" if disks.size > 1

      delete_single_disk(disks.first)
      self
    end

    def delete_all_disks_by_name(name)
      disks = find_disks_by_name(name)
      success = true
      disks.each do |disk|
        begin
          delete_single_disk(disk)
        rescue RuntimeError => e
          success = false
          Config.logger.error("Disk deletion failed with exception: #{e}")
        end
      end

      fail CloudError,
           "Failed to delete one or more of the disks with name '#{name}'. Check logs for details." unless success
      self
    end

    def storage_profile_xml_node(name)
      return nil if name.nil?

      storage_profile = entity_xml.storage_profile(name)
      unless storage_profile
        fail ObjectNotFoundError,
             "Storage profile '#{name}' does not exist"
      end

      storage_profile
    end


    def instantiate_ovf_params(vapp_name, vdc)
      instantiate_ovf_params = VCloudSdk::Xml::WrapperFactory.create_instance("InstantiateOvfParams").tap do |params|
        params.name = vapp_name
      end

      connection.post(entity_xml.instantiate_ovf_link,
        instantiate_ovf_params,
        Xml::MEDIA_TYPE[:INSTANTIATE_OVF_PARAMS])
    end


    def instantiate_ovf(vapp_name,directory)
      if vapp_exists?(vapp_name)
        fail CloudError,
             "vApp '#{vapp_name}' already exists in vdc #{entity_xml.name}"
      end

      Config.logger.info "Uploading vApp #{vapp_name} to #{entity_xml.name}"
      vapp = instantiate_ovf_params(vapp_name, entity_xml)
      vapp = upload_vapp_files(vapp, ovf_directory(directory))

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

    private

    def storage_profile_records
      connection
        .get("/api/query?type=orgVdcStorageProfile&filter=vdcName==#{URI.encode(name)}")
        .org_vdc_storage_profile_records
    end

    def disk_create_params(name, capacity, bus_type, bus_sub_type, vm)
      Xml::WrapperFactory.create_instance("DiskCreateParams").tap do |params|
        params.name = name
        params.size_bytes = capacity * 1024 * 1024 # VCD expects bytes
        params.bus_type = bus_type
        params.bus_sub_type = bus_sub_type
        params.add_locality(connection.get(vm.href)) if vm # Use xml form of vm
      end
    end

    def delete_single_disk(disk)
      Config.logger.info "Deleting disk '#{disk.name}', link #{disk.href}"
      fail CloudError,
           "Disk '#{disk.name}', link #{disk.href} is attached to VM '#{disk.vm.name}'" if disk.attached?

      entity_xml = connection.get(disk.href)
      task = connection.delete(entity_xml.remove_link.href)
      monitor_task(task)

      Config.logger.info "Disk deleted successfully"
    end

  end
end
