require "forwardable"
require_relative "infrastructure"

module VCloudSdk
  class VM
    include Infrastructure

    extend Forwardable
    def_delegator :entity_xml, :name

    def initialize(session, link)
      @session = session
      @link = link
    end

    def href
      @link
    end

    def attach_disk(disk)
      task = connection.post(entity_xml.attach_disk_link.href,
                             disk_attach_or_detach_params(disk),
                             Xml::MEDIA_TYPE[:DISK_ATTACH_DETACH_PARAMS])
      task = monitor_task(task)

      Config.logger.info "Disk '#{disk.name}' is attached to VM '#{name}'"
      task
    end

    private

    def disk_attach_or_detach_params(disk)
      Xml::WrapperFactory
        .create_instance("DiskAttachOrDetachParams")
        .tap do |params|
        params.disk_href = disk.href
      end
    end
  end
end
