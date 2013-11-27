require_relative "session"
require_relative "infrastructure"

module VCloudSdk
  # Represents the calalog item in calalog.
  class CatalogItem
    include Infrastructure

    attr_reader :name

    def initialize(session, catalog_item_link)
      @session = session
      @catalog_item_link = catalog_item_link
      @name = @catalog_item_link.name
    end

    def type
      entity[:type]
    end

    def entity
      retrieve_xml_node.entity
    end

    private

    def retrieve_xml_node
      unless @catalog_item_xml_node
        @catalog_item_xml_node = connection.get(@catalog_item_link)
      end

      @catalog_item_xml_node
    end
  end
end
