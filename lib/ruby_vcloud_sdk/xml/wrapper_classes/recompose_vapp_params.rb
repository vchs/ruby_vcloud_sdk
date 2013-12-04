module VCloudSdk
  module Xml
    class RecomposeVAppParams < Wrapper
      def description
        get_nodes("Description").first
      end

      def description=(desc)
        description.content = desc
      end

      def all_eulas_accepted=(value)
        eulas_node = get_nodes("AllEULAsAccepted").first
        eulas_node.content = value
      end

      def add_source_item(entity_to_add_href)
        return unless entity_to_add_href

        node_sourced_item = create_child("SourcedItem")
        node_source = add_child("Source", nil, nil, node_sourced_item)
        node_source["href"] = entity_to_add_href

        get_nodes("AllEULAsAccepted").first.node.before(node_sourced_item)
      end

      def add_delete_item(entity_to_delete_href)
        return unless entity_to_delete_href

        node_delete_item = create_child("DeleteItem")
        node_delete_item["href"] = entity_to_delete_href

        get_nodes("AllEULAsAccepted").first.node.after(node_delete_item)
      end
    end
  end
end
