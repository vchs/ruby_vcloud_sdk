require_relative "infrastructure"

module VCloudSdk
  class VM
    include Infrastructure

    def initialize(session, link)
      @session = session
      @link = link
    end

    def href
      @link
    end

    def name
      entity_xml.name
    end
  end
end
