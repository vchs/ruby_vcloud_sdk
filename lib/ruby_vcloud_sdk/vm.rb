require "forwardable"
require_relative "infrastructure"
require_relative "powerable"
require_relative "internal_disk"
require_relative "nic"

module VCloudSdk

  #################################################################################################
  # This class represents a VM belonging a vApp of the Virtual Data Center.
  #################################################################################################
  class VM
    include Infrastructure
    include Powerable

    extend Forwardable
    def_delegator :entity_xml, :name

    ###############################################################################################
    # Initializes a VM object associated with a vCloud Session and the VMs link. 
    # @param session   [Session] The client's session
    # @param link      [String]  The XML representation of the VM
    ###############################################################################################
    def initialize(session, link)
      @session = session
      @link = link
    end

    ###############################################################################################
    # Returns the identifier of the VM (uuid) 
    # @return      [String]  The identifier of the VM
    ###############################################################################################
    def id    
      id = entity_xml.urn
      id.split(":")[3]      
    end

    ###############################################################################################
    # Returns the vCloud link of the VM 
    # @return      [String]  The vCloud link of the VM
    ###############################################################################################
    def href
      @link
    end

    ###############################################################################################
    # Returns the memory of the VM 
    # @return      [String]  The memory in MB of the VM
    ###############################################################################################
    def memory
      m = entity_xml
            .hardware_section
            .memory
      allocation_units = m.get_rasd_content(Xml::RASD_TYPES[:ALLOCATION_UNITS])
      bytes = eval_memory_allocation_units(allocation_units)

      virtual_quantity = m.get_rasd_content(Xml::RASD_TYPES[:VIRTUAL_QUANTITY]).to_i
      memory_mb = virtual_quantity * bytes / BYTES_PER_MEGABYTE
      fail CloudError,
           "Size of memory is less than 1 MB." if memory_mb == 0
      memory_mb
    end

    ###############################################################################################
    # Modifies the memory size of the VM.
    # @param   size     [String]  The new memory size in MB.
    # @throw
    ###############################################################################################
    def memory=(size)
      fail(CloudError,
           "Invalid vm memory size #{size}MB") if size <= 0

      Config
        .logger
        .info "Changing the vm memory to #{size}MB."

      payload = entity_xml
      payload.change_memory(size)

      task = connection.post(payload.reconfigure_link.href,
                             payload,
                             Xml::MEDIA_TYPE[:VM])
      monitor_task(task)
      self
    end


    ###############################################################################################
    # Returns the number of virtual cpus of the VM.
    # @return   [Integer]  The number of virtual cpus of the VM
    # @throw
    ###############################################################################################
    def vcpu
      cpus = entity_xml
              .hardware_section
              .cpu
              .get_rasd_content(Xml::RASD_TYPES[:VIRTUAL_QUANTITY])

      fail CloudError,
           "Uable to retrieve number of virtual cpus of VM #{name}" if cpus.nil?
      cpus.to_i
    end

    ###############################################################################################
    # Modifies the number of virtual cpus of the VM.
    # @param   count     [Integer]  The new number of virtual cpus.
    # @throw
    ###############################################################################################
    def vcpu=(count)
      fail(CloudError,
           "Invalid virtual CPU count #{count}") if count <= 0

      Config
        .logger
        .info "Changing the virtual CPU count to #{count}."

      payload = entity_xml
      payload.change_cpu_count(count)

      task = connection.post(payload.reconfigure_link.href,
                             payload,
                             Xml::MEDIA_TYPE[:VM])
      monitor_task(task)
      self
    end

    def name=(name)
      payload = entity_xml
      payload.name = name
      task = connection.post(payload.reconfigure_link.href,
                             payload,
                             Xml::MEDIA_TYPE[:VM])
      monitor_task(task)
      self
    end

    ###############################################################################################
    # Reconfigures the VM with the parameters passed in a hash.
    # All params are optional.
    # @param   options     [Hash]  The parameters of the VM.
    #                       :name         [String] The name of the VM
    #                       :description  [String] The description of the VM
    #                       :vcpu         [String] The value for number of CPU
    #                       :memory       [String] The value for memory in MB
    #                       :nics         [Array]   Array of Hashes representing the nics 
    #                                              to attach to VM
    #                                       :network_name [String] The network to attach nic
    #                                       :ip           [String] Optional. The IP of the nic
    #                                       :mac          [String] Optional. The MAC of the nic
    #                       :disks        [Array]   Array of Hases representing the disks to 
    #                                              attach to VM                                                   
    #                       :vapp_name    [String] The name of the vApp
    # @return [VM]
    ###############################################################################################
    def reconfigure(options)     

      payload             = entity_xml
      payload.name        = options[:name] if !options[:name].nil?
      payload.description = options[:description] if !options[:name].nil?
      payload.change_cpu_count(options[:vcpu]) if !options[:name].nil?
      payload.change_memory(options[:memory]) if !options[:name].nil?
      nic_index = add_nic_index

      if options[:nics] !=[]
        #ADD NICS
        options[:nics].each { |nic|

            mac_address = nic[:mac]

            if !mac_address or (mac_address and !find_nic_by_mac(mac_address))              
              
              network_name = nic[:network_name]
              ip_addressing_mode = Xml::IP_ADDRESSING_MODE[:POOL]

              ip = ""

              if !nic[:ip].nil?
                ip_addressing_mode = Xml::IP_ADDRESSING_MODE[:MANUAL] 
                ip = nic[:ip]
              end
                        

              # Add Network to vapp
              vapp.add_network_by_name(network_name) if !vapp.list_networks.include? "#{network_name}"
              # Add NIC          
              payload.hardware_section.add_item(nic_params(payload.hardware_section,
                             nic_index,
                             network_name,
                             ip_addressing_mode,
                             ip))
              # Connect NIC
              payload.network_connection_section.add_item(network_connection_params(payload.network_connection_section,
                                            nic_index,
                                            network_name,
                                            ip_addressing_mode,
                                            ip))
              #Add the mac address passed
              if mac_address
                payload
                .network_connection_section
                .network_connections.last
                .mac_address = mac_address
              end
              nic_index = nic_index + 1  
            end
        }
      end

      #DELETE NICS
      macs = []
      options[:nics].each do |nic|
        macs.push(nic[:mac])
      end   

      if macs.empty?
        payload.delete_nics(*nics)
      else
        nics.each do |nc| 
          options[:nics].each do |nic|         
            payload.delete_nics(nc) if !macs.include? "#{nc.mac_address}"                      
          end
        end
      end

      task = connection.post(payload.reconfigure_link.href,
                             payload,
                             Xml::MEDIA_TYPE[:VM])
      monitor_task(task)
      self
    end

    ###############################################################################################
    # Returns the IP addresses assigned to the VM or nil.
    # @return   [Array or nil]  The IP addresses or nil.
    ###############################################################################################
    def ip_address       
      entity_xml.ip_address
    end

    def list_networks
      entity_xml
        .network_connection_section
        .network_connections
        .map { |network_connection| network_connection.network }
    end

    def nics
      primary_index = entity_xml
                        .network_connection_section
                        .primary_network_connection_index
      entity_xml
        .network_connection_section
        .network_connections
        .map do |network_connection|
          VCloudSdk::NIC.new(network_connection,
                             network_connection.network_connection_index == primary_index)
        end
    end

    def find_nic_by_mac(mac)
      primary_index = entity_xml
                        .network_connection_section
                        .primary_network_connection_index
       net = entity_xml
        .network_connection_section
        .network_connections.find do |n|
          n.mac_address == mac.to_s
        end 
      if net     
        return VCloudSdk::NIC.new(net,net.network_connection_index == primary_index)
      else
        return false
        fail(CloudError,
           "No NIC found with MAC #{mac} in VM #{name}")
      end       
    end

    def independent_disks
      hardware_section = entity_xml.hardware_section
      disks = []
      hardware_section.hard_disks.each do |disk|
        disk_link = disk.host_resource.attribute("disk")
        unless disk_link.nil?
          disks << VCloudSdk::Disk.new(@session, disk_link.to_s)
        end
      end
      disks
    end

    def list_disks
      entity_xml.hardware_section.hard_disks.map do |disk|
        disk_link = disk.host_resource.attribute("disk")
        if disk_link.nil?
          disk.element_name
        else
          "#{disk.element_name} (#{VCloudSdk::Disk.new(@session, disk_link.to_s).name})"
        end
      end
    end

    ###############################################################################################
    # Attaches an independent disk to VM.
    # @param   disk     [Disk]  The disk object to attach.
    # @throw
    ###############################################################################################
    def attach_disk(disk)
      fail CloudError,
           "Disk '#{disk.name}' of link #{disk.href} is attached to VM '#{disk.vm.name}'" if disk.attached?

      task = connection.post(entity_xml.attach_disk_link.href,
                             disk_attach_or_detach_params(disk),
                             Xml::MEDIA_TYPE[:DISK_ATTACH_DETACH_PARAMS])
      monitor_task(task)

      Config.logger.info "Disk '#{disk.name}' is attached to VM '#{name}'"
      self
    end

    def detach_disk(disk)
      parent_vapp = vapp
      if parent_vapp.status == "SUSPENDED"
        fail VmSuspendedError,
             "vApp #{parent_vapp.name} suspended, discard state before detaching disk."
      end

      unless (vm = disk.vm).href == href
        fail CloudError,
             "Disk '#{disk.name}' is attached to other VM - name: '#{vm.name}', link '#{vm.href}'"
      end

      task = connection.post(entity_xml.detach_disk_link.href,
                             disk_attach_or_detach_params(disk),
                             Xml::MEDIA_TYPE[:DISK_ATTACH_DETACH_PARAMS])
      monitor_task(task)

      Config.logger.info "Disk '#{disk.name}' is detached from VM '#{name}'"
      self
    end

    def insert_media(catalog_name, media_file_name)
      catalog = find_catalog_by_name(catalog_name)
      media = catalog.find_item(media_file_name, Xml::MEDIA_TYPE[:MEDIA])

      vm = entity_xml
      media_xml = connection.get(media.href)
      Config.logger.info("Inserting media #{media_xml.name} into VM #{vm.name}")

      wait_for_running_tasks(media_xml, "Media '#{media_xml.name}'")

      task = connection.post(vm.insert_media_link.href,
                             media_insert_or_eject_params(media),
                             Xml::MEDIA_TYPE[:MEDIA_INSERT_EJECT_PARAMS])
      monitor_task(task)
      self
    end

    def eject_media(catalog_name, media_file_name)
      catalog = find_catalog_by_name(catalog_name)
      media = catalog.find_item(media_file_name, Xml::MEDIA_TYPE[:MEDIA])

      vm = entity_xml
      media_xml = connection.get(media.href)
      Config.logger.info("Ejecting media #{media_xml.name} from VM #{vm.name}")

      wait_for_running_tasks(media_xml, "Media '#{media_xml.name}'")

      task = connection.post(vm.eject_media_link.href,
                             media_insert_or_eject_params(media),
                             Xml::MEDIA_TYPE[:MEDIA_INSERT_EJECT_PARAMS])
      monitor_task(task)
      self
    end

    def add_nic(
          network_name,
          ip_addressing_mode = Xml::IP_ADDRESSING_MODE[:POOL],
          mac_address = nil,
          ip = nil) 

      fail CloudError,
           "Invalid IP_ADDRESSING_MODE '#{ip_addressing_mode}'" unless Xml::IP_ADDRESSING_MODE
                                                                       .each_value
                                                                       .any? { |m| m == ip_addressing_mode }

      fail CloudError,
           "IP is missing for MANUAL IP_ADDRESSING_MODE" if ip_addressing_mode == Xml::IP_ADDRESSING_MODE[:MANUAL] &&
                                                              ip.nil?

      fail ObjectNotFoundError,
           "Network #{network_name} is not added to parent VApp #{vapp.name}" unless vapp
                                                                                       .list_networks
                                                                                       .any? { |n| n == network_name }
      payload = entity_xml
      fail CloudError,
           "VM #{name} is powered-on and vmware tools are not installed, cannot add NIC." if is_status?(payload, :POWERED_ON) && !self.vmtools? ##si està power-on i no té les vmware tools, error

      nic_index = add_nic_index

      Config.logger
        .info("Adding NIC #{nic_index}, network #{network_name} using mode '#{ip_addressing_mode}' #{ip.nil? ? "" : "IP: #{ip}"}")

      # Add NIC
      payload
        .hardware_section
        .add_item(nic_params(payload.hardware_section,
                             nic_index,
                             network_name,
                             ip_addressing_mode,
                             ip))
      # Connect NIC
      payload
        .network_connection_section
        .add_item(network_connection_params(payload.network_connection_section,
                                            nic_index,
                                            network_name,
                                            ip_addressing_mode,
                                            ip))

      # Si li subministrem una mac, li afegeix la que li diem
      if mac_address
        payload
          .network_connection_section
          .network_connections.last
          .mac_address = mac_address
      end
      
      task = connection.post(payload.reconfigure_link.href,
                             payload,
                             Xml::MEDIA_TYPE[:VM])
      monitor_task(task)
      self
    end

    def delete_nics(*nics)
      payload = entity_xml
      fail CloudError,
           "VM #{name} is powered-on and cannot delete NIC." if is_status?(payload, :POWERED_ON)

      payload.delete_nics(*nics)
      task = connection.post(payload.reconfigure_link.href,
                             payload,
                             Xml::MEDIA_TYPE[:VM])
      monitor_task(task)
      self
    end

    def operating_system
      entity_xml.operating_system
    end

    def vmtools_version 
        entity_xml.vm_tools
    end

    def vmtools?    
       !entity_xml.vm_tools.nil?   
    end

    def acquire_VMRC_ticket

        fail(CloudError,
           "The VM must be powered on") if self.status != "POWERED_ON"

        Config.logger.info(
          "Obtaining VMware VMware Remote Console Ticket on #{name} ...")
        task = connection.post(entity_xml.vmrc_ticket_link.href,nil)
        task = task.nil? ? nil : task.content                
       
    end

    def install_vmtools
      Config.logger.info(
        "Mounting VMware tools on #{name} ...")
      task = connection.post(entity_xml.install_vmtools_link.href,nil)
      monitor_task(task)
      self 
    end    
   

    def product_section_properties
      product_section = entity_xml.product_section
      return [] if product_section.nil?

      product_section.properties
    end

    def product_section_properties=(properties)
      Config.logger.info(
        "Updating VM #{name} production sections with properties: #{properties.inspect}")
      task = connection.put(entity_xml.product_sections_link.href,
                            product_section_list_params(properties),
                            Xml::MEDIA_TYPE[:PRODUCT_SECTIONS])
      monitor_task(task)
      self
    end

    def internal_disks
      hardware_section = entity_xml.hardware_section
      internal_disks = []
      hardware_section.hard_disks.each do |disk|
        disk_link = disk.host_resource.attribute("disk")
        if disk_link.nil?
          internal_disks << VCloudSdk::InternalDisk.new(disk)
        end
      end
      internal_disks
    end

    def create_internal_disk(
          capacity,
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
        .info "Creating internal disk #{name} of #{capacity}MB."

      payload = entity_xml
      payload.add_hard_disk(capacity, bus_type, bus_sub_type)

      task = connection.post(payload.reconfigure_link.href,
                             payload,
                             Xml::MEDIA_TYPE[:VM])
      monitor_task(task)
      self
    end

    def delete_internal_disk_by_name(name)
      payload = entity_xml

      unless payload.delete_hard_disk?(name)
        fail ObjectNotFoundError, "Internal disk '#{name}' is not found"
      end

      task = connection.post(payload.reconfigure_link.href,
                             payload,
                             Xml::MEDIA_TYPE[:VM])
      monitor_task(task)
      self
    end

    ############################################################################################################
    # Set up the options for the OS of the VM
    # All params are optional.
    # @param   customization     [Hash]  The parameters of the guestOS customization. All parameters are 
    #                                    optional.
    #                             :computer_name      [String] The name of the computer
    #                             :admin_pass         [String] The password for the Administrator/root user
    #                             :reset_pass         [String] Values "true" or "false". To reset password.
    #                             :custom_script      [String] The customization script (Max 49,000 characters)
    #                          
    # @return [VM]
    ############################################################################################################
    def customization(customization)
      link    = entity_xml.guest_customization_link
      payload = connection.get(link)
  
      payload = add_customization(payload,customization)    
    
      task = connection.put(link,
                            payload,
                            Xml::MEDIA_TYPE[:GUEST_CUSTOMIZATION_SECTION])
      monitor_task(task)
      self
    end

    private

    def add_nic_index
      # nic index begins with 0
      i = 0
      nic_indexes = nics.map { |n| n.nic_index }
      while (nic_indexes.include?(i))
        i += 1
      end
      i
    end

    def disk_attach_or_detach_params(disk)
      Xml::WrapperFactory
        .create_instance("DiskAttachOrDetachParams")
        .tap do |params|
        params.disk_href = disk.href
      end
    end

    def vapp
      vapp_link = entity_xml.vapp_link
      VCloudSdk::VApp.new(@session, vapp_link.href)
    end

    def media_insert_or_eject_params(media)
      Xml::WrapperFactory.create_instance("MediaInsertOrEjectParams").tap do |params|
        params.media_href = media.href
      end
    end

    def eval_memory_allocation_units(allocation_units)
      # allocation_units is in the form of "byte * modifier * base ^ exponent" such as "byte * 2^20"
      # "modifier", "base" and "exponent" are positive integers and optional.
      # "base" and "exponent" must be present together.
      # Parsing logic: remove starting "byte" and first char "*" and replace power "^" with ruby-understandable "**"
      bytes = allocation_units.sub(/byte\s*(\*)?/, "").sub(/\^/, "**")
      return 1 if bytes.empty? # allocation_units is "byte" without "modifier", "base" or "exponent"
      fail unless bytes =~ /(\d+\s*\*)?(\d+\s*\*\*\s*\d+)?/
      eval bytes
    rescue
      raise ApiError,
            "Unexpected form of AllocationUnits of memory: '#{allocation_units}'"
    end

    def nic_params(section, nic_index, network_name, addressing_mode, ip)
      is_primary = section.nics.empty?
      item = Xml::WrapperFactory
               .create_instance("Item", nil, section.doc_namespaces)

      Xml::NicItemWrapper
        .new(item)
        .tap do |params|
          params.nic_index = nic_index
          params.network = network_name
          params.set_ip_addressing_mode(addressing_mode, ip)
          params.is_primary = is_primary
      end
    end

    def network_connection_params(section, nic_index, network_name, addressing_mode, ip)
      Xml::WrapperFactory
        .create_instance("NetworkConnection", nil, section.doc_namespaces)
        .tap do |params|
          params.network_connection_index = nic_index
          params.network = network_name
          params.ip_address_allocation_mode = addressing_mode
          params.ip_address = ip unless ip.nil?
          params.is_connected = true
      end
    end

    def add_customization(section, customization)
      section
      .tap do |params|
          params.enable          
          params.computer_name = customization[:computer_name] unless customization[:computer_name].nil?
          params.admin_pass    = customization[:admin_pass] unless customization[:admin_pass].nil?
          params.script        = customization[:custom_script] unless customization[:custom_script].nil?
        end
    end

    def product_section_list_params(properties)
      Xml::WrapperFactory.create_instance("ProductSectionList").tap do |params|
        properties.each do |property|
          params.add_property(property)
        end
      end
    end

    BYTES_PER_MEGABYTE = 1_048_576 # 1048576 = 1024 * 1024 = 2^20
  end
  #################################################################################################
end
