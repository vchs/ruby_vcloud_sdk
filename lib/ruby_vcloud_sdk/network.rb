require_relative "infrastructure"
require_relative "ip_ranges"

module VCloudSdk

  ######################################################################################
  # This class represents a virtual Network in the virtual data center.
  ######################################################################################
  class Network
    include Infrastructure

    extend Forwardable
    def_delegator :entity_xml, :name
    
    ####################################################################################
    # Initializes a vApp object associated with a vCloud Session and the Network's link. 
    # @param session   [Session] The client's session.
    # @param link      [String]  The vCloud link of the network.
    ####################################################################################   
    def initialize(session, link)
      @session = session
      @link = link
    end

    ####################################################################################
    # Returns the identifier of the Network (uuid). 
    # @return      [String]  The identifier of the Network.
    ####################################################################################
    def id      
      @link.href.split("/")[5]      
    end
    
    ####################################################################################
    # Returns the description of the Network.
    # @return      [String]  The identifier of the Network.
    ####################################################################################
    def description
      entity_xml.description
    end
    
    ####################################################################################
    # Returns the fence mode of the Network.
    # @return      [String]  The fence mode of the Network.
    ####################################################################################
    def fence_mode
      entity_xml.fence_mode
    end

    ####################################################################################
    # Returns the vCloud link of the Network.
    # @return      [String]  The vCloud link of the Network.
    ####################################################################################
    def href
      #puts entity_xml
      @link
    end

    ####################################################################################
    # Returns array of IpRanges objects of the Network
    # @return [IpRanges] an array of IpRanges
    ####################################################################################
    def ip_ranges
      entity_xml
        .ip_scope
        .ip_ranges
        .ranges
        .reduce(IpRanges.new) do |result, i|
          result + IpRanges.new("#{i.start_address}-#{i.end_address}")
        end
    end

    ####################################################################################
    # Returns the list of allocated ips of the Network
    # @return [String] an array of allocated ip addresses 
    ####################################################################################
    def allocated_ips
      allocated_addresses = connection.get(entity_xml.allocated_addresses_link)
      allocated_addresses.ip_addresses.map do |i|
        i.ip_address
      end
    end
  end
  ######################################################################################
end
