require "forwardable"
require_relative "infrastructure"
require_relative "ip_ranges"

module VCloudSdk

  ##############################################################################
  # This class represents a Edge Gateway in the Virtual Data Center. 
  ##############################################################################
  class EdgeGateway
    include Infrastructure

    extend Forwardable
    def_delegator :entity_xml, :name

    ############################################################################
    # Initializes a EdgeGateway object associated with a vCloud Session and the
    # the Edge Gateway's link 
    # @param session   [Session] The client's session
    # @param link      [String]  The xml representation of the Edge Gateway
    ############################################################################
    def initialize(session, link)
      @session  = session
      @link     = link
    end

    ############################################################################
    # Add Firewall rules to the Edge Gateyay.
    # @param rules [Array]   Array of Hashes representing the rules to be added.
    #                      :name      [String] The name of the rule. 
    #                      :ip_src    [String] The source IP or "Any".
    #                      :ip_dest   [String] The destination IP or "Any".
    #                      :port_src  [String] The source Port or "Any".
    #                      :port_dest [String] The destination IP or "Any".
    #                      :prot      [String] "TCP","UDP", "TCP & UDP", "ICMP",
    #                                           "ANY"    .
    #                      :action    [String] The action to be applied.It can be 
    #                                          "allow" or "deny".
    #                      :enabled   [String] To enable or disable the rule.
    #                                          The options are "true" or "false".
    #
    # @return      [EdgeGateway]  The Edge Gateway object.
    ############################################################################
    def add_fw_rules(rules)
      link      = entity_xml.configure_services_link
      payload   = entity_xml.add_rules(rules)

      task      = connection.post(link,
                            payload.configure_services,
                            Xml::ADMIN_MEDIA_TYPE[:EDGE_SERVICES_CONFIG])
      monitor_task(task)
      self
    end
    
    ############################################################################
    # Remove the Firewall rules with IPs destination passed as an argument 
    # @param ips [Array] Array of IPs destination addresses                    
    # @return    [EdgeGateway]  The Edge Gateway object.
    ############################################################################
    def remove_fw_rules(ips)
      link     = entity_xml.configure_services_link
      payload  = entity_xml.remove_rules(ips)

      task    = connection.post(link,
                            payload.configure_services,
                            Xml::ADMIN_MEDIA_TYPE[:EDGE_SERVICES_CONFIG])
      monitor_task(task)
      self
    end

    def ent
      entity_xml
    end
    
    def public_ip_ranges
      uplink_gateway_interface = entity_xml
                                   .gateway_interfaces
                                   .find { |g| g.interface_type == "uplink" }

      ip_ranges = uplink_gateway_interface.ip_ranges
      return IpRanges.new unless ip_ranges

      ip_ranges
        .ranges
        .reduce(IpRanges.new) do |result, i|
          result + IpRanges.new("#{i.start_address}-#{i.end_address}")
        end
    end
  end
end
