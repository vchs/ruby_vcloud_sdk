module VCloudSdk

  ################################################################################
  # This class represents a NIC (Network Interface Card).
  # The NIC are attached to VM and connected to Networks.
  ################################################################################
  class NIC
    extend Forwardable

    def_delegators :@entity_xml,
                   :ip_address, :is_connected, :mac_address,
                   :ip_address_allocation_mode, :network

    attr_reader :is_primary

    ##############################################################################
    # Initialize a NIC. 
    # @param entity_xml    [String]   The XML representation for the NIC.
    # @param is_primary    [Boolean]  It defines if the NIC is the main or not.
    ##############################################################################
    def initialize(entity_xml, is_primary)
      @entity_xml = entity_xml      
      @is_primary = is_primary
    end

    ##############################################################################
    # Retrun the network connection index. 
    # @return    [Integer]   The newtork connection index.
    ##############################################################################
    def network_connection_index
      @entity_xml.network_connection_index.to_i
    end

    ##############################################################################
    # Retuns the NIC status. 
    # @return   [Boolean]     Return "True" if the NIC is connected
    #                                "False" otherwise
    ##############################################################################
    def is_connected
      @entity_xml.is_connected == "true"
    end

    alias_method :nic_index, :network_connection_index
  end
end
