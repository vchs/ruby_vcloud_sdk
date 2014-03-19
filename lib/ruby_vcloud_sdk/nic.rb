module VCloudSdk
  class NIC
    extend Forwardable

    def_delegators :@entity_xml,
                   :ip_address, :is_connected, :mac_address,
                   :ip_address_allocation_mode, :network

    attr_reader :is_primary

    def initialize(entity_xml, is_primary)
      @entity_xml = entity_xml
      @is_primary = is_primary
    end

    def network_connection_index
      @entity_xml.network_connection_index.to_i
    end

    def is_connected
      @entity_xml.is_connected == "true"
    end

    alias_method :nic_index, :network_connection_index
  end
end
