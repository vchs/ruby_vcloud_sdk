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
  end
end
