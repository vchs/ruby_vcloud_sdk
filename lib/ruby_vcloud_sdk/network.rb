require_relative "infrastructure"
require_relative "ip_ranges"

module VCloudSdk
  class Network
    include Infrastructure

    def initialize(session, link)
      @session = session
      @link = link
    end

    def name
      entity_xml.name
    end

    def ip_ranges
      entity_xml.ip_ranges
        .ranges
        .reduce(IpRanges.new) do |result, i|
          result + IpRanges.new("#{i.start_address}-#{i.end_address}")
        end
    end

    def allocated_ips
      allocated_addresses = connection.get(entity_xml.allocated_addresses_link)
      allocated_addresses.ip_addresses.map do |i|
        i.ip_address
      end
    end
  end
end
