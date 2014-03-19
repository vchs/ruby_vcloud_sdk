module VCloudSdk
  module Xml
    class ProductSection < Wrapper
      def add_property(property)
        property_node = add_child("Property",
                                  ovf_namespace_prefix,
                                  OVF)
        property_node["#{ovf_namespace_prefix}:type"] =
          property["type"].nil? ? "string" : property["type"]
        property_node["#{ovf_namespace_prefix}:key"] = property["key"]
        property_node["#{ovf_namespace_prefix}:value"] = property["value"]
        property_node["#{ovf_namespace_prefix}:password"] =
          property["password"] if property["password"] # default to false
        property_node["#{ovf_namespace_prefix}:userConfigurable"] =
          property["userConfigurable"] if property["userConfigurable"] # default to false

        %w[Label Description].each do |k|
          add_child_node_property(property_node, property, k)
        end

        if property["value"].nil?
          value_node = add_child("Value", ovf_namespace_prefix, OVF, property_node)
          value_node.attribute("value").value = property["value"]
        end
      end

      def properties
        get_nodes("Property", nil, true, OVF).map do |property_node|
          property = {}
          %w[type key value password userConfigurable].each do |k|
            attr = property_node.attribute(k)
            property[k] = attr.nil? ? "" : attr.content
          end

          %w[Label Description].each do |k|
            read_child_node_property(property_node, property, k)
          end

          value_node = property_node.get_nodes("Value", nil, true, OVF).first
          property["value"] = value_node.attribute("value").content unless value_node.nil?
          property
        end
      end

      private

      def add_child_node_property(property_node, property, key)
        unless property[key].nil?
          child_node = add_child(key, ovf_namespace_prefix, OVF, property_node)
          child_node.content = property[key]
        end
      end

      def read_child_node_property(property_node, property, key)
        child_node = property_node.get_nodes(key, nil, true, OVF).first
        property[key] = child_node.content unless child_node.nil?
      end
    end
  end
end
