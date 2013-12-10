require "forwardable"
require_relative "session"
require_relative "infrastructure"

module VCloudSdk
  class Disk
    include Infrastructure

    extend Forwardable
    def_delegators :entity_xml,
                   :name, :bus_type, :bus_sub_type,
                   :size_mb, :status

    def initialize(session, link)
      @session = session
      @link = link
    end
  end
end
