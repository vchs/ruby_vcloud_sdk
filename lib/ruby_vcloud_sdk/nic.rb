module VCloudSdk
  class NIC
    extend Forwardable

    def_delegators :@entity_xml,
                   :ip_address, :is_connected, :mac_address,
                   :ip_address_allocation_mode

    def initialize(entity_xml)
      @entity_xml = entity_xml
    end

    def network_connection_index
      @entity_xml.network_connection_index.to_i
    end
  end
end
