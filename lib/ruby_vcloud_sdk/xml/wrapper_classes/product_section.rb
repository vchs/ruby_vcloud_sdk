module VCloudSdk
  module Xml
    class ProductSection < Wrapper
      def add_property(property)
        property_node = add_child("Property",
                                  ovf_namespace_prefix,
                                  OVF)
        property_node["#{ovf_namespace_prefix}:type"] = property["type"].nil? ? "string" : property["type"]
        property_node["#{ovf_namespace_prefix}:key"] = property["key"]
        property_node["#{ovf_namespace_prefix}:value"] = property["value"]
        property_node["#{ovf_namespace_prefix}:password"] = property["password"] if property["password"]

        unless property["Label"].nil?
          label_node = add_child("Label", ovf_namespace_prefix, OVF, property_node)
          label_node.content = property["Label"]
        end
      end

      def properties
        get_nodes("Property", nil, true, OVF).map do |property_node|
          property = {}
          property["type"] = property_node.attribute("type").content
          property["key"] = property_node.attribute("key").content
          property["value"] = property_node.attribute("value").content
          property["password"] = property_node.attribute("password").content

          label_node = property_node.get_nodes("Label", nil, true, OVF).first
          property["Label"] = label_node.content unless label_node.nil?

          property
        end
      end
    end
  end
end
