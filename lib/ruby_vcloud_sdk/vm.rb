require_relative "infrastructure"

module VCloudSdk
  class VM
    include Infrastructure

    def initialize(session, vm_link)
      @session = session
      @vm_link = vm_link
    end

    def href
      @vm_link
    end

    def name
      connection
        .get(@vm_link)
        .name
    end
  end
end
