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

    def independent_disks
      hardware_section = entity_xml.hardware_section
      disks = []
      hardware_section.hard_disks.each do |disk|
        disk_link = disk.host_resource.attribute("disk")
        unless disk_link.nil?
          disks << VCloudSdk::Disk.new(@session, disk_link.to_s)
        end
      end
      disks
    end

    def list_disks
      entity_xml.hardware_section.hard_disks.map do |disk|
        disk.element_name
      end
    end

    def attach_disk(disk)
      task = connection.post(entity_xml.attach_disk_link.href,
                             disk_attach_or_detach_params(disk),
                             Xml::MEDIA_TYPE[:DISK_ATTACH_DETACH_PARAMS])
      task = monitor_task(task)

      Config.logger.info "Disk '#{disk.name}' is attached to VM '#{name}'"
      task
    end

    def detach_disk(disk)
      parent_vapp = vapp
      if parent_vapp.status == "SUSPENDED"
        fail VmSuspendedError,
             "vApp #{parent_vapp.name} suspended, discard state before detaching disk."
      end

      task = connection.post(entity_xml.detach_disk_link.href,
                             disk_attach_or_detach_params(disk),
                             Xml::MEDIA_TYPE[:DISK_ATTACH_DETACH_PARAMS])
      task = monitor_task(task)

      Config.logger.info "Disk '#{disk.name}' is detached from VM '#{name}'"
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

    def vapp
      vapp_link = entity_xml.vapp_link
      VCloudSdk::VApp.new(@session, vapp_link.href)
    end
  end
end
