require_relative "session"
require_relative "infrastructure"

module VCloudSdk
  # Represents the calalog item in calalog.
  class CatalogItem
    include Infrastructure

    def initialize(session, catalog_item_link)
      @session = session
      @catalog_item_link = catalog_item_link
    end

    def name
      entity[:name]
    end

    def type
      entity[:type]
    end

    def href
      entity[:href]
    end

    def remove_link
      connection.get(@catalog_item_link).remove_link
    end

    def delete
      xml_node = connection.get(@catalog_item_link)

      delete_entity xml_node.entity

      connection.delete(xml_node.remove_link)
    end

    private

    def entity
      catalog_item_xml_node = connection.get(@catalog_item_link)
      catalog_item_xml_node.entity
    end

    def delete_entity entity
      linked_obj = connection.get(entity)

      unless linked_obj.running_tasks.empty?
        Config.logger.info "#{linked_obj.href} has tasks in progress, wait until done."
        linked_obj.running_tasks.each do |task|
          monitor_task(task)
        end
      end

      Config.logger.info "Deleting #{linked_obj.href}."
      monitor_task(connection.delete(linked_obj))
      Config.logger.info "#{linked_obj.href} deleted."
    end
  end
end
