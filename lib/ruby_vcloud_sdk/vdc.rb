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

    def initialize(session, vdc_xml_obj)
      @session = session
      @vdc_xml_obj = vdc_xml_obj
    end

    def storage_profiles
      connection.get("/api/query?type=orgVdcStorageProfile&filter=vdcName==#{URI.encode(name)}")
        .org_vdc_storage_profile_records.map do |storage_profile|
          VCloudSdk::VdcStorageProfile.new(storage_profile)
        end
    end

    def find_storage_profile_by_name(name)
      storage_profiles.each do |storage_profile|
        return storage_profile if storage_profile.name == name
      end

      nil
    end

    def vapps
      @vdc_xml_obj.vapps.map do |vapp|
        VCloudSdk::VApp.new(@session, vapp)
      end
    end

    def find_vapp_by_name(name)
      vapps.each do |vapp|
        return vapp if vapp.name == name
      end

      fail ObjectNotFoundError, "VApp '#{name}' is not found"
    end

    def resources
      cpu = VCloudSdk::CPU.new(@vdc_xml_obj.available_cpu_cores)
      memory = VCloudSdk::Memory.new(@vdc_xml_obj.available_memory_mb)
      VCloudSdk::Resources.new(cpu, memory)
    end

    def networks
      @session.org.networks.map do |network|
        VCloudSdk::Network.new(@session, network)
      end
    end

    def find_network_by_name(name)
      networks.each do |network|
        return network if network.name == name
      end

      nil
    end

    def disks
      @vdc_xml_obj.disks.map do |disk_link|
        VCloudSdk::Disk.new(@session, disk_link)
      end
    end

    def find_disk_by_name(name)
      disks.each do |disk|
        return disk if disk.name == name
      end

      fail ObjectNotFoundError, "Disk '#{name}' is not found"
    end

    def storage_profile_xml_node(name)
      return nil if name.nil?

      storage_profile = @vdc_xml_obj.storage_profile(name)
      unless storage_profile
        fail "Storage profile '#{name}' does not exist"
      end

      storage_profile
    end
  end
end
