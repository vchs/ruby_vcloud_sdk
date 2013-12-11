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

module VCloudSdk
  class VDC
    include Infrastructure

    extend Forwardable
    def_delegators :@vdc_xml_obj,
                   :name, :upload_link, :upload_media_link,
                   :instantiate_vapp_template_link

    BUS_TYPE = {
      "scsi" => Xml::HARDWARE_TYPE[:SCSI_CONTROLLER]
    }

    BUS_SUB_TYPE = {
      "lsilogic" => Xml::BUS_SUB_TYPE[:LSILOGIC]
    }

    private_constant :BUS_TYPE, :BUS_SUB_TYPE

    def initialize(session, vdc_xml_obj)
      @session = session
      @vdc_xml_obj = vdc_xml_obj
    end

    def storage_profiles
      storage_profile_records.map do |storage_profile|
        VCloudSdk::VdcStorageProfile.new(storage_profile)
      end
    end

    def list_storage_profiles
      @vdc_xml_obj.storage_profiles.map do |storage_profile|
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

    def vapps
      @vdc_xml_obj.vapps.map do |vapp_link|
        VCloudSdk::VApp.new(@session, vapp_link)
      end
    end

    def list_vapps
      @vdc_xml_obj.vapps.map do |vapp_link|
        vapp_link.name
      end
    end

    def find_vapp_by_name(name)
      @vdc_xml_obj.vapps.each do |vapp_link|
        if vapp_link.name == name
          return VCloudSdk::VApp.new(@session, vapp_link)
        end
      end

      fail ObjectNotFoundError, "VApp '#{name}' is not found"
    end

    def resources
      cpu = VCloudSdk::CPU.new(@vdc_xml_obj.available_cpu_cores)
      memory = VCloudSdk::Memory.new(@vdc_xml_obj.available_memory_mb)
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

    def find_network_by_name(name)
      @session.org.networks.each do |network_link|
        if network_link.name == name
          return VCloudSdk::Network.new(@session, network_link)
        end
      end

      fail ObjectNotFoundError, "Network '#{name}' is not found"
    end

    def disks
      @vdc_xml_obj.disks.map do |disk_link|
        VCloudSdk::Disk.new(@session, disk_link)
      end
    end

    def list_disks
      @vdc_xml_obj.disks.map do |disk_link|
        disk_link.name
      end
    end

    def find_disk_by_name(name)
      disks = @vdc_xml_obj
                .disks
                .select { |disk_link| disk_link.name == name }
                .map { |disk_link| VCloudSdk::Disk.new(@session, disk_link) }

      if disks.empty?
        fail ObjectNotFoundError, "Disk '#{name}' is not found"
      end

      disks
    end

    def disk_exists?(name)
      disks.any? do |disk|
        disk.name == name
      end
    end

    def create_disk(
          name,
          size_mb,
          vm = nil,
          bus_type = "scsi",
          bus_sub_type = "lsilogic")

      fail(CloudError,
           "Invalid size in MB #{size_mb}") if size_mb <= 0

      bus_type = BUS_TYPE[bus_type.downcase]
      fail(CloudError,
           "Invalid bus type!") unless bus_type

      bus_sub_type = BUS_SUB_TYPE[bus_sub_type.downcase]
      fail(CloudError,
           "Invalid bus sub type!") unless bus_sub_type

      Config
        .logger
        .info "Creating independent disk #{name} of #{size_mb}MB."

      disk = connection.post(@vdc_xml_obj.add_disk_link,
                             disk_create_params(name, size_mb, bus_type, bus_sub_type, vm),
                             Xml::MEDIA_TYPE[:DISK_CREATE_PARAMS])

      wait_for_running_tasks(disk, "Disk #{name}")

      VCloudSdk::Disk.new(@session, disk.href)
    end

    def storage_profile_xml_node(name)
      return nil if name.nil?

      storage_profile = @vdc_xml_obj.storage_profile(name)
      unless storage_profile
        fail "Storage profile '#{name}' does not exist"
      end

      storage_profile
    end

    private

    def storage_profile_records
      connection
        .get("/api/query?type=orgVdcStorageProfile&filter=vdcName==#{URI.encode(name)}")
        .org_vdc_storage_profile_records
    end

    def disk_create_params(name, size_mb, bus_type, bus_sub_type, vm)
      Xml::WrapperFactory.create_instance("DiskCreateParams").tap do |params|
        params.name = name
        params.size_bytes = size_mb * 1024 * 1024 # VCD expects bytes
        params.bus_type = bus_type
        params.bus_sub_type = bus_sub_type
        params.add_locality(connection.get(vm.href)) if vm # Use xml form of vm
      end
    end
  end
end
