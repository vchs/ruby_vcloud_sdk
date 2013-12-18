require_relative "session"
require_relative "infrastructure"

module VCloudSdk
  # Represents the calalog item in calalog.
  class CatalogItem
    include Infrastructure

    def initialize(session, link)
      @session = session
      @link = link
    end

    def name
      entity_xml.entity[:name]
    end

    def type
      entity_xml.entity[:type]
    end

    def href
      entity_xml.entity[:href]
    end

    def delete
      delete_catalog_item_entity entity_xml.entity

      connection.delete(entity_xml.remove_link)
    end

    private

    def delete_catalog_item_entity entity
      linked_obj = connection.get(entity)

      wait_for_running_tasks(linked_obj, linked_obj.href)
      Config.logger.info "Deleting #{linked_obj.href}."
      monitor_task(connection.delete(linked_obj))
      Config.logger.info "#{linked_obj.href} deleted."
    end
  end
end
