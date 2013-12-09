module VCloudSdk
  module Xml
    class Vdc < Wrapper
      def add_disk_link
        get_nodes(XML_TYPE[:LINK],
                  type: MEDIA_TYPE[:DISK_CREATE_PARAMS])
                  .first
      end

      def disks(name = nil)
        if name.nil?
          get_nodes("ResourceEntity",
                    type: MEDIA_TYPE[:DISK])
        else
          get_nodes("ResourceEntity",
                    type: MEDIA_TYPE[:DISK], name: name)
                    .first
        end
      end

      def instantiate_vapp_template_link
        get_nodes(XML_TYPE[:LINK],
                  type: MEDIA_TYPE[:INSTANTIATE_VAPP_TEMPLATE_PARAMS])
                  .first
      end

      def upload_link
        get_nodes(XML_TYPE[:LINK],
                  type: MEDIA_TYPE[:UPLOAD_VAPP_TEMPLATE_PARAMS])
                  .first
      end

      def upload_media_link
        get_nodes(XML_TYPE[:LINK],
                  type: MEDIA_TYPE[:MEDIA])
                  .first
      end

      def vapps
        get_nodes(:ResourceEntity, type: MEDIA_TYPE[:VAPP])
      end

      # vApp Template names are not unique so multiple ones can be returned.
      def get_vapp_templates(name)
        get_nodes("ResourceEntity",
                  type: MEDIA_TYPE[:VAPP_TEMPLATE], name: name)
      end

      def available_networks
        get_nodes("Network",
                  type: MEDIA_TYPE[:NETWORK])
      end

      def available_network(name)
        get_nodes("Network",
                  type: MEDIA_TYPE[:NETWORK], name: name)
                  .first
      end

      def storage_profiles
        get_nodes(:VdcStorageProfile, type: MEDIA_TYPE[:VDC_STORAGE_PROFILE])
      end

      def storage_profile(name)
        get_nodes(:VdcStorageProfile,
                  type: MEDIA_TYPE[:VDC_STORAGE_PROFILE], name: name)
                  .first
      end

      def available_cpu_cores
        cpu_resource = get_nodes("ComputeCapacity")
                         .first.get_nodes("Cpu").first
        available_cpu_clock_speed = get_available_resource(cpu_resource)

        # clock units can only be MHz or GHz
        units = cpu_resource.get_nodes("Units").first.content
        if units == "MHz"
          available_cpu_clock_speed = available_cpu_clock_speed / 1000
        end

        # We assume 1 GHz is converted to 1 vCpu core
        available_cpu_clock_speed
      end

      def available_memory_mb
        memory_resource = get_nodes("ComputeCapacity")
                            .first.get_nodes("Memory").first
        available_memory = get_available_resource(memory_resource)

        # clock units can only be MB or GB
        units = memory_resource.get_nodes("Units").first.content
        available_memory = available_memory * 1024 if units == "GB"
        available_memory
      end

      private

      def get_available_resource(resource_node)
        limited_resource = resource_node.get_nodes("Limit").first.content.to_i
        return -1 if limited_resource == 0
        limited_resource - resource_node.get_nodes("Used").first.content.to_i
      end
    end
  end
end
