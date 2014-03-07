require "forwardable"
require_relative "session"
require_relative "infrastructure"

module VCloudSdk
  class Disk
    include Infrastructure

    extend Forwardable
    def_delegators :entity_xml,
                   :name, :bus_type, :bus_sub_type,
                   :capacity, :status

    def initialize(session, link)
      @session = session
      @link = link
    end

    def href
      @link
    end

    def attached?
      !vm_reference.nil?
    end

    def vm
      vm_link = vm_reference
      fail ObjectNotFoundError,
           "No vm is attached to disk '#{name}'" if vm_link.nil?

      VCloudSdk::VM.new(@session, vm_link.href)
    end

    private

    def vm_reference
      connection
        .get(entity_xml.vms_link)
        .vm_reference
    end
  end
end
