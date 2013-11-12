require_relative "infrastructure"
require_relative "ip_ranges"

module VCloudSdk
  class Network
    include Infrastructure

    attr_reader :name

    def initialize(session, network_link)
      @session = session
      @network_link = network_link
      @name = @network_link.name
    end

    def ip_ranges
      network = connection.get(@network_link)
      ip_ranges = nil
      network.ip_ranges
        .ranges
        .each do |i|
          new_range = IpRanges.new "#{i.start_address}-#{i.end_address}"
          if ip_ranges
            ip_ranges.add! new_range
          else
            ip_ranges = new_range
          end
        end
      ip_ranges
    end
  end
end
