module VCloudSdk
  module Xml

    class InstantiateVAppTemplateParams < Wrapper
      def name
        @root["name"]
      end

      def description
        get_nodes("Description").first
      end

      def all_eulas_accepted=(value)
        eulas_node = get_nodes("AllEULAsAccepted").first
        eulas_node.content = value
      end

      def name=(name)
        @root["name"] = name
      end

      def description=(desc)
        description.content = desc
      end

      def linked_clone=(value)
        @root["linkedClone"] = value.to_s
      end

      def disk_size(id,size,vm_link)
        return unless id    
        sourced = Xml::WrapperFactory
        .create_instance("SourcedVmInstantiationParams", nil, nil)
        sourced.resize_disk(id,size,vm_link)
        nm = get_nodes("IsSourceDelete").first.node
        nm.after(sourced.node)
      end

      def source=(src)
        source_node = get_nodes("Source").first
        source_node["href"] = src["href"]
        source_node["id"] = src["id"]
        source_node["type"] = src["type"]
        source_node["id"] = src["id"]
      end

      def set_locality=(locality)
        return unless locality

        raise "vApp locality already set." if @local_exists
        @local_exists = true

        locality.each do |k,v|
          node_sp = create_child("SourcedVmInstantiationParams",
                                 namespace.prefix,
                                 namespace.href)
          is_source_delete.node.after(node_sp)

          node_sv = add_child("Source",
                              namespace.prefix,
                              namespace.href,
                              node_sp)
          node_sv["type"] = k.type
          node_sv["name"] = k.name
          node_sv["href"] = k.href

          node_lp = create_child("LocalityParams",
                                 namespace.prefix,
                                 namespace.href)
          node_sv.after(node_lp)

          node_re = add_child("ResourceEntity",
                              namespace.prefix,
                              namespace.href,
                              node_lp)
          node_re["type"] = v.type
          node_re["name"] = v.name
          node_re["href"] = v.href
        end
      end

      def set_network_config(vapp_network_name, vdc_netowrk_href, fence_mode)
        instantiation_param = get_nodes("InstantiationParams").first

        net_config_section = add_child("NetworkConfigSection",
                                       namespace.prefix,
                                       namespace.href,
                                       instantiation_param.node)

        ovf_info = add_child("Info", "ovf", OVF, net_config_section)
        ovf_info.content = "Configuration parameters for logical networks"

        network_config = create_child("NetworkConfig",
                                      namespace.prefix,
                                      namespace.href)
        ovf_info.after(network_config)
        network_config["networkName"] = vapp_network_name

        configuration = add_child("Configuration",
                                  namespace.prefix,
                                  namespace.href,
                                  network_config)

        parent_network = add_child("ParentNetwork",
                                   namespace.prefix,
                                   namespace.href,
                                   configuration)
        parent_network["href"] = vdc_netowrk_href

        fence_node = create_child("FenceMode",
                                  namespace.prefix,
                                  namespace.href)
        parent_network.after(fence_node)
        fence_node.content = fence_mode
      end

      private

      def is_source_delete
        get_nodes("IsSourceDelete").first
      end
    end

  end
end
