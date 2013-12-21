require_relative "infrastructure"
require_relative "ip_ranges"

module VCloudSdk
  class EdgeGateway
    include Infrastructure

    def initialize(session, link)
      @session = session
      @link = link
    end

    def public_ip_ranges
      public_ip_ranges = nil
      uplink_gateway_interface = entity_xml
                                   .gateway_interfaces
                                   .find { |g| g.interface_type == "uplink" }

      ip_ranges = uplink_gateway_interface.ip_ranges
      return nil unless ip_ranges

      ip_ranges
        .ranges
        .each do |i|
        new_range = IpRanges.new "#{i.start_address}-#{i.end_address}"
        if public_ip_ranges
          public_ip_ranges += new_range
        else
          public_ip_ranges = new_range
        end
      end
      public_ip_ranges
    end
  end
end
