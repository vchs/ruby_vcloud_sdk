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

    def delete
      disk_name = name
      task = connection.delete(entity_xml.remove_link.href)
      task = monitor_task(task)

      Config.logger.info "Disk '#{disk_name}' of link #{@link} is deleted successfully"
      task
    end
  end
end
