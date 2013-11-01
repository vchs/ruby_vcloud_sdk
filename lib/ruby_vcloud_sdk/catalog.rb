require_relative "vdc"
require_relative "session"
require_relative "infrastructure"

module VCloudSdk

  class Catalog
    include VCloudSdk::Infrastructure

    attr_reader :name

    def initialize(session, catalog_xml_obj)
      @session = session
      @connection = session.connection
      @catalog_xml_obj = catalog_xml_obj
      @name = catalog_xml_obj.name
    end

    def id
      @catalog_xml_obj.href_id
    end

    def catalog_items
      @connection.get("/api/admin/catalog/#{id}").catalog_items
    end

    def delete_all_catalog_items
      catalog_items.each do |catalog_item_xml_obj|
        catalog_item = @connection.get("/api/catalogItem/#{catalog_item_xml_obj.href_id}")
        Config.logger.info "Deleting catalog item \"#{catalog_item.name}\""
        @connection.delete(catalog_item.remove_link)
      end
    end

  end
end
