require "netaddr"
require "set"

module VCloudSdk
  class IpRanges
    attr_reader :ranges

    def initialize(value = nil)
      @ranges = Set.new

      parse_ip_ranges(value) unless value.nil?
    end

    def add(ip_ranges)
      ip_ranges = validate_ip_ranges ip_ranges
      result = IpRanges.new
      result.ranges.merge @ranges
      result.ranges.merge ip_ranges.ranges
      result
    end
    alias_method :+, :add

    def include?(ip_ranges)
      ip_ranges = validate_ip_ranges ip_ranges
      @ranges.superset? ip_ranges.ranges
    end

    def subtract(ip_ranges)
      ip_ranges = validate_ip_ranges ip_ranges
      difference = IpRanges.new
      difference.ranges.merge @ranges
      difference.ranges.subtract ip_ranges.ranges

      difference
    end
    alias_method :-, :subtract

    protected

    attr_writer :ranges

    private

    def parse_ip_ranges(ip_ranges_string)
      fail "Parameter is not a string" unless ip_ranges_string.is_a? String

      # remove white space
      ip_ranges_string.gsub(/\s+/, "").split(",").map do |i|
        parse_ip_range(i)
      end
    end

    def parse_ip_range(ip_range_string)
      case ip_range_string
      when /-/
        ips = ip_range_string.split("-")
        unless ips.length == 2
          fail "Invalid input: #{ips.length} field/fields separated by '-'"
        end

        merge_into_ranges ips[0], ips[1]
      when /\//
        ips = NetAddr::CIDR.create(ip_range_string)
        merge_into_ranges ips.first, ips.last
      else
        # A single IP address such as "10.142.15.11"
        ip = NetAddr::CIDR.create(ip_range_string)
        fail "IPv6 is not supported" if ip.is_a?(NetAddr::CIDRv6)
        @ranges.add ip.ip
      end
    end

    def merge_into_ranges(ip_start_string, ip_end_string)
      ip_start = NetAddr::CIDR.create(ip_start_string)
      ip_end = NetAddr::CIDR.create(ip_end_string)
      if ip_start.is_a?(NetAddr::CIDRv6) || ip_end.is_a?(NetAddr::CIDRv6)
        fail "IPv6 is not supported"
      end

      if ip_start > ip_end
        fail "IP #{ip_start.ip} is bigger than IP #{ip_end.ip}"
      end

      @ranges.merge((ip_start..ip_end).map(&:ip))
    end

    def validate_ip_ranges(ip_ranges)
      ip_ranges = IpRanges.new(ip_ranges) if ip_ranges.is_a? String
      unless ip_ranges.is_a? IpRanges
        fail "Unable to parse object that is not IpRange or string"
      end
      ip_ranges
    end
  end
end
