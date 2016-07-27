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

  ###############################################################################################
  # This class represents a Virtual Data Center in vCloud.
  ###############################################################################################
  class VDC
    include Infrastructure

    extend Forwardable
    def_delegators :entity_xml,
                   :name, :upload_link, :upload_media_link,
                   :instantiate_vapp_template_link

    public :find_network_by_name, :network_exists?

    #############################################################################################
    # Initializes a VDC object associated with a vCloud Session and the VDC's link. 
    # @param session   [Session] The client's session.
    # @param link      [String]  The vCloud link of the vApp.
    #############################################################################################
    def initialize(session, link)
      @session = session
      @link = link
    end

    #############################################################################################
    # Returns the storage profiles assoaciated with the Virtual Data Center. 
    # @return         [VdcStorageProfile]  The storafe profiles of de VDC.
    #############################################################################################
    def storage_profiles
      storage_profile_records.map do |storage_profile|
        VCloudSdk::VdcStorageProfile.new(storage_profile)
      end
    end

    #############################################################################################
    # Returns the name's list of storage profiles assoaciated with the Virtual Data Center. 
    # @return         [String]  The array of storage profiles's names of de VDC.
    #############################################################################################
    def list_storage_profiles
      storage_profile_records.map do |storage_profile|
        storage_profile.name
      end
    end

    #############################################################################################
    # Returns the storage profile identified by name. 
    # @return         [VdcStorageProfile]  The storafe profiles of the VDC.
    #############################################################################################
    def find_storage_profile_by_name(name)
      storage_profile_records.each do |storage_profile|
        if storage_profile.name == name
          return VCloudSdk::VdcStorageProfile.new(storage_profile)
        end
      end

      fail ObjectNotFoundError, "Storage profile '#{name}' is not found"
    end

    #############################################################################################
    # Obtain if the storage profile identified by name exists.
    # @return         [Boolean]  If the storage profile identified by name exists, returns "True".
    #############################################################################################
    def storage_profile_exists?(name)
      storage_profile_records.any? do |storage_profile|
        storage_profile.name == name
      end
    end

    #############################################################################################
    # Returns the vApp's list hosted in the VDC. 
    # @return         [VApp]  The array of vApp hosted in the VDC.
    #############################################################################################
    def vapps
      entity_xml.vapps.map do |vapp_link|
        VCloudSdk::VApp.new(@session, vapp_link)
      end
    end

    #############################################################################################
    # Returns the name's list of vApps hosted in the Virtual Data Center. 
    # @return         [String]  The array of vApps's names.
    #############################################################################################
    def list_vapps
      entity_xml.vapps.map do |vapp_link|
        vapp_link.name
      end
    end

    #############################################################################################
    # Returns the vApp identified by name.
    # @return         [VApp]  The vApp hosted in VDC.
    #############################################################################################
    def find_vapp_by_name(name)
      entity_xml.vapps.each do |vapp_link|
        if vapp_link.name == name
          return VCloudSdk::VApp.new(@session, vapp_link)
        end
      end

      fail ObjectNotFoundError, "VApp '#{name}' is not found"
    end

    #############################################################################################
    # Returns the vApp identified by uuid.
    # @return         [VApp]  The vApp hosted in VDC.
    #############################################################################################
    def find_vapp_by_id(uuid)      
      entity_xml.vapps.each do |vapp_link|              
        if vapp_link.href.split("/")[5] == "vapp-#{uuid}"          
          return VCloudSdk::VApp.new(@session, vapp_link)
        end
      end

      fail ObjectNotFoundError, "VApp '#{uuid}' is not found"
    end

    #############################################################################################
    # Obtain if the vApp identified by name exists.
    # @return         [Boolean]  If the vApp identified by name exists, returns "True".
    #############################################################################################
    def vapp_exists?(name)
      entity_xml.vapps.any? do |vapp|
        vapp.name == name
      end
    end
    
    #############################################################################################
    # Creates Resources object representing the CPU and Memory of the VDC.
    # @return         [Resouces]  The Resource object of the VDC.
    #############################################################################################
    def resources      
      cpu = VCloudSdk::CPU.new(entity_xml.available_cpu_mhz,entity_xml.limit_cpu_mhz)
      memory = VCloudSdk::Memory.new(entity_xml.available_memory_mb,entity_xml.limit_memory_mb)
      VCloudSdk::Resources.new(cpu,memory)
    end

    #############################################################################################
    # Returns the list of the Networks created in the VDC.
    # @return         [Network]  The array of Networks created in the VDC.
    #############################################################################################
    def networks
      @session.org.networks.map do |network_link|
        VCloudSdk::Network.new(@session, network_link)
      end
    end

    #############################################################################################
    # Returns the name's list of Networks created in the Virtual Data Center. 
    # @return         [String]  The array of Network's names.
    #############################################################################################
    def list_networks
      @session.org.networks.map do |network_link|
        network_link.name
      end
    end

    #############################################################################################
    # Returns the list of Edge Gateways created in the VDC. 
    # @return         [EdgeGateway]  The array of Edge Gateways created in the VDC.
    #############################################################################################
    def edge_gateways
      connection
        .get(entity_xml.edge_gateways_link)
        .edge_gateway_records
        .map do |edge_gateway_link|
        VCloudSdk::EdgeGateway.new(@session, edge_gateway_link.href)
      end
    end

    #############################################################################################
    # Returns the list of Disks created in the VDC. 
    # @return         [Disks]  The array of Disk created in the VDC.
    #############################################################################################
    def disks
      entity_xml.disks.map do |disk_link|
        VCloudSdk::Disk.new(@session, disk_link)
      end
    end

    #############################################################################################
    # Returns the name's list of Disks created in the Virtual Data Center. 
    # @return         [String]  The array of Disk's names.
    #############################################################################################
    def list_disks
      entity_xml.disks.map do |disk_link|
        disk_link.name
      end
    end

    #############################################################################################
    # Returns the Disks identified by name. 
    # @return         [Disk]  The Disk or Disks created in VDC.
    #############################################################################################
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

    #############################################################################################
    # Obtain if the Disk identified by name exists.
    # @return         [Boolean]  If the vApp identified by name exists, returns "True".
    #############################################################################################
    def disk_exists?(name)
      list_disks.any? do |disk_name|
        disk_name == name
      end
    end

    #############################################################################################
    # Creates a Disk in the Virtual Data Center.
    # @param name          [String]   The disk's name.
    # @param capacity      [Integer]  The capacity in MB of the disk.
    # @return              [Disk]     The object created.disk_create_param.
    #############################################################################################
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

    #############################################################################################
    # Deletes the Disk identified by "name"..
    # @return              [VDC]     The Virtual Data Center.
    #############################################################################################
    def delete_disk_by_name(name)
      disks = find_disks_by_name(name)
      fail CloudError,
           "#{disks.size} disks with name #{name} were found" if disks.size > 1

      delete_single_disk(disks.first)
      self
    end

    #############################################################################################
    # Deletes ALL the Disks identified by "name"..
    # @return              [VDC]     The Virtual Data Center.
    #############################################################################################
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
           "Failed to delete one or more of the disks with name '#{name}'. 
                                                      Check logs for details." unless success
      self
    end

    #############################################################################################
    # Returns the storage profile identified by name in XML.
    # @return         [XML]  The storafe profiles of de VDC.
    #############################################################################################
    def storage_profile_xml_node(name)
      return nil if name.nil?

      storage_profile = entity_xml.storage_profile(name)
      unless storage_profile
        fail ObjectNotFoundError,
             "Storage profile '#{name}' does not exist"
      end

      storage_profile
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
           "Disk '#{disk.name}', link #{disk.href} is attached 
                                            to VM '#{disk.vm.name}'" if disk.attached?

      entity_xml = connection.get(disk.href)
      task = connection.delete(entity_xml.remove_link.href)
      monitor_task(task)

      Config.logger.info "Disk deleted successfully"
    end
  end
end
