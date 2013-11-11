require_relative "infrastructure"
require_relative "ip_range"

module VCloudSdk
  class Network
    include Infrastructure

    attr_reader :name

    def initialize(session, network_link)
      @session = session
      @network_link = network_link
      @name = @network_link.name
    end

    def ip_range
      network = connection.get(@network_link)
      ip_range = nil
      network.ip_ranges
        .ip_range
        .each do |i|
          new_range = IpRange.new "#{i.start_address}-#{i.end_address}"
          if ip_range
            ip_range.add! new_range
          else
            ip_range = new_range
          end
        end
      ip_range
    end

    def allocated_ips
      network = connection.get(@network_link)
      allocated_addresses = connection.get(network.allocated_addresses_link)
      allocated_addresses.ip_addresses.map do |i|
        i.ip_address
      end
    end
  end
end
