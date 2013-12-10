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
  end
end
