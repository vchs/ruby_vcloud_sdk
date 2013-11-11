require "netaddr"

module VCloudSdk

  class IpRange
    attr_reader :value

    def initialize(value)
      fail "Unable to parse a non-string object" unless value.is_a? String

      # remove white space
      ip_range_value = value.gsub(/\s+/, "")
      @value = ip_range_value.split(",").map do |i|
        parse_ip_range(i)
      end
    end

    def add(ip_range)
      fail "Unable to parse object that is not IpRange" \
        unless ip_range.is_a? IpRange
      @value += ip_range.value
    end

    def include?(ip_range)
      @value.each do |v|
        ip_range.value.each do |o|
          return false if v.first > o.first || o.last > v.last
        end
      end

      true
    end

    private

    def parse_ip_range(ip_range_value)
      case ip_range_value
      when /-/
        ips = ip_range_value.split("-")
        unless ips.length == 2
          fail "Invalid input: #{ips.length} field/fields separated by '-'"
        end

        ip_start = NetAddr::CIDR.create(ips[0])
        ip_end = NetAddr::CIDR.create(ips[1])
        fail "IP #{ip_start.ip} is bigger than IP #{ip_end.ip}" if ip_start > ip_end

        ip_start..ip_end
      when /\//
        ips = NetAddr::CIDR.create(ip_range_value)
        NetAddr::CIDR.create(ips.first)..NetAddr::CIDR.create(ips.last)
      else
        # A single IP address such as "10.142.15.11",
        # but we still make it a range
        NetAddr::CIDR.create(ip_range_value)..
          NetAddr::CIDR.create(ip_range_value)
      end
    end
  end

end
