require_relative "session"
require_relative "infrastructure"

module VCloudSdk
  # Represents the calalog item in catalog.
  class CatalogItem
    include Infrastructure

    def initialize(session, link)
      @session = session
      @link = link
    end

    def name
      entity_xml.entity[:name]
    end

    def id      
      id = entity_xml.urn
      id.split(":")[3] 
    end

    def description 
      entity_xml.description     
    end

    def vapp_template_id
      entity_xml.entity[:href].split("/")[5]
    end     

    def type
      entity_xml.entity[:type]
    end

    def href
      entity_xml.entity[:href]
    end

    def date
      entity_xml.date
    end
  end
end
