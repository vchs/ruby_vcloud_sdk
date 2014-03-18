module VCloudSdk
  module Xml
    class VirtualHardwareSection < Wrapper
      def add_item(item)
        system_node = get_nodes("System", nil, true, OVF).first
        system_node.node.after(item.node)
      end

      def edit_link
        get_nodes(XML_TYPE[:LINK],
                  { rel: XML_TYPE[:EDIT],
                    type: MEDIA_TYPE[:VIRTUAL_HARDWARE_SECTION] },
                  true).first
      end

      def cpu
        hardware.find do |h|
          h.get_rasd_content(RASD_TYPES[:RESOURCE_TYPE]) == HARDWARE_TYPE[:CPU]
        end
      end

      def memory
        hardware.find do |h|
          h.get_rasd_content(RASD_TYPES[:RESOURCE_TYPE]) == HARDWARE_TYPE[:MEMORY]
        end
      end

      def scsi_controller
        hardware.find { |h| h.get_rasd_content(RASD_TYPES[:RESOURCE_TYPE]) ==
          HARDWARE_TYPE[:SCSI_CONTROLLER] }
      end

      def highest_instance_id
        hardware.map{|h| h.instance_id}.max
      end

      def nics
        items = hardware.select do |h|
          h.get_rasd_content(RASD_TYPES[:RESOURCE_TYPE]) == HARDWARE_TYPE[:NIC]
        end
        items.map { |i| NicItemWrapper.new(i) }
      end

      def remove_nic(index)
        remove_hw(HARDWARE_TYPE[:NIC], index)
      end

      def remove_hw(hw_type, index)
        index = index.to_s
        item = hardware.find do |h|
          h.get_rasd_content(RASD_TYPES[:RESOURCE_TYPE]) == hw_type &&
            h.get_rasd_content(RASD_TYPES[:ADDRESS_ON_PARENT]) == index
        end
        if item
          item.node.remove
        else
          fail ObjectNotFoundError,
               "Cannot remove hw item #{hw_type}:#{index}, does not exist."
        end
      end

      def reconcile_primary_network(primary_index)
        primary_index = primary_index.to_s
        hardware.select do |item|
          item.get_rasd_content(RASD_TYPES[:RESOURCE_TYPE]) == HARDWARE_TYPE[:NIC]
        end.each do |item|
          if item.get_rasd_content(RASD_TYPES[:ADDRESS_ON_PARENT]) == primary_index
            item.get_rasd(RASD_TYPES[:CONNECTION]).attribute("primaryNetworkConnection").value = "true"
          else
            item.get_rasd(RASD_TYPES[:CONNECTION]).attribute("primaryNetworkConnection").value = "false"
          end
        end
      end

      def hard_disks
        items = hardware.select do |h|
          h.get_rasd_content(
          RASD_TYPES[:RESOURCE_TYPE]) == HARDWARE_TYPE[:HARD_DISK]
        end
        items.map { |i| HardDiskItemWrapper.new(i) }
      end

      def hardware
        get_nodes("Item", nil, false, OVF)
      end
    end
  end
end
