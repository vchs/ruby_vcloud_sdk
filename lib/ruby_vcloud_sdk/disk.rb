require "forwardable"
require_relative "session"
require_relative "infrastructure"

module VCloudSdk
  class Disk
    include Infrastructure

    extend Forwardable

    attr_reader :name

    def initialize(session, disk_link)
      @session = session
      @disk_link = disk_link
      @name = disk_link.name
    end

    def disk_xml
      connection.get(@disk_link)
    end

    def_delegators :disk_xml,
                   :bus_type, :bus_sub_type,
                   :size_mb, :status
  end
end
