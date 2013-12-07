require "forwardable"
require_relative "session"
require_relative "infrastructure"

module VCloudSdk
  class Disk
    include Infrastructure

    extend Forwardable
    def_delegators :@disk_xml,
                   :name, :bus_type, :bus_sub_type,
                   :size_mb, :status

    def initialize(session, disk_link)
      @session = session
      @disk_xml = connection.get(disk_link)
    end
  end
end
