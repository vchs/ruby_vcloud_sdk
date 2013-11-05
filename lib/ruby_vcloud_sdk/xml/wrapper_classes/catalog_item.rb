module VCloudSdk
  module Xml

    class CatalogItem < Wrapper
      def entity=(entity)
        entity_node = self.entity
        entity_node[:name] = entity.name
        entity_node[:id] = entity.urn
        entity_node[:href] = entity.href
        entity_node[:type] = entity.type
      end

      def entity
        get_nodes(XML_TYPE[:ENTITY]).first
      end
    end

  end
end
