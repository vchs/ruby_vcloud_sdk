require "forwardable"
require_relative "infrastructure"
require_relative "powerable"

module VCloudSdk
  class VM
    include Infrastructure
    include Powerable

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
        disk_link = disk.host_resource.attribute("disk")
        if disk_link.nil?
          disk.element_name
        else
          "#{disk.element_name} (#{VCloudSdk::Disk.new(@session, disk_link.to_s).name})"
        end
      end
    end

    def attach_disk(disk)
      fail CloudError,
           "Disk '#{disk.name}' of link #{disk.href} is attached to VM '#{disk.vm.name}'" if disk.attached?

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

      unless (vm = disk.vm).href == href
        fail CloudError,
             "Disk '#{disk.name}' is attached to other VM - name: '#{vm.name}', link '#{vm.href}'"
      end

      task = connection.post(entity_xml.detach_disk_link.href,
                             disk_attach_or_detach_params(disk),
                             Xml::MEDIA_TYPE[:DISK_ATTACH_DETACH_PARAMS])
      task = monitor_task(task)

      Config.logger.info "Disk '#{disk.name}' is detached from VM '#{name}'"
      task
    end

    def insert_media(catalog_name, media_file_name)
      insert_or_eject_media(catalog_name,
                            media_file_name,
                            :insert_media_link,
                            "Inserting media %s into VM %s")
    end

    def eject_media(catalog_name, media_file_name)
      insert_or_eject_media(catalog_name,
                            media_file_name,
                            :eject_media_link,
                            "Ejecting media %s from VM %s")
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

    def media_insert_or_eject_params(media)
      Xml::WrapperFactory.create_instance("MediaInsertOrEjectParams").tap do |params|
        params.media_href = media.href
      end
    end

    def insert_or_eject_media(catalog_name, media_file_name, link, log_msg)
      catalog = find_catalog_by_name(catalog_name)
      media = catalog.find_item(media_file_name, Xml::MEDIA_TYPE[:MEDIA])

      vm = entity_xml
      media_xml = connection.get(media.href)
      Config.logger.info(sprintf(log_msg, media_xml.name, vm.name))

      wait_for_running_tasks(media_xml, "Media '#{media_xml.name}'")

      task = connection.post(vm.public_send(link).href,
                             media_insert_or_eject_params(media),
                             Xml::MEDIA_TYPE[:MEDIA_INSERT_EJECT_PARAMS])
      monitor_task(task)
    end
  end
end
