require "forwardable"
require_relative "infrastructure"
require_relative "powerable"

module VCloudSdk
  class VM
    include Infrastructure
    include Powerable

    extend Forwardable
    def_delegator :entity_xml, :name

    def initialize(session, link)
      @session = session
      @link = link
    end

    def href
      @link
    end

    # returns size of memory in megabytes
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

    # returns number of virtual cpus of VM
    def vcpu
      cpus = entity_xml
              .hardware_section
              .cpu
              .get_rasd_content(Xml::RASD_TYPES[:VIRTUAL_QUANTITY])

      fail CloudError,
           "Uable to retrieve number of virtual cpus of VM #{name}" if cpus.nil?
      cpus.to_i
    end

    def list_networks
      entity_xml
        .network_connection_section
        .network_connections
        .map { |network_connection| network_connection.network }
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

    def attach_disk(disk)
      fail CloudError,
           "Disk '#{disk.name}' of link #{disk.href} is attached to VM '#{disk.vm.name}'" if disk.attached?

      task = connection.post(entity_xml.attach_disk_link.href,
                             disk_attach_or_detach_params(disk),
                             Xml::MEDIA_TYPE[:DISK_ATTACH_DETACH_PARAMS])
      task = monitor_task(task)

      Config.logger.info "Disk '#{disk.name}' is attached to VM '#{name}'"
      task
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
      task = monitor_task(task)

      Config.logger.info "Disk '#{disk.name}' is detached from VM '#{name}'"
      task
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
    end

    def add_nic(
          network_name,
          ip_addressing_mode = Xml::IP_ADDRESSING_MODE[:POOL],
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
      if is_status?(payload, :POWERED_ON)
        fail CloudError,
             "VM #{name} is powered-on and cannot add NIC."
      end

      nic_index = list_networks.size # nic index begins with 0

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

      task = connection.post(payload.reconfigure_link.href,
                             payload,
                             Xml::MEDIA_TYPE[:VM])
      monitor_task(task)
    end

    private

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

    BYTES_PER_MEGABYTE = 1_048_576 # 1048576 = 1024 * 1024 = 2^20
  end
end
