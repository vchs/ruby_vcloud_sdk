require "netaddr"

module VCloudSdk
  class IpRanges
    attr_reader :ranges

    def initialize(value)
      fail "Unable to parse a non-string object" unless value.is_a? String

      # remove white space
      ip_range_value = value.gsub(/\s+/, "")
      @ranges = ip_range_value.split(",").map do |i|
        parse_ip_range(i)
      end
    end

    def add(ip_ranges)
      fail "Unable to parse object that is not IpRange" \
        unless ip_ranges.is_a? IpRanges
      @ranges += ip_ranges.ranges
    end

    def include?(ip_ranges)
      each do |v|
        ip_ranges.each do |o|
          return false if v.first > o.first || o.last > v.last
        end
      end

      true
    end

    def [](index)
      @ranges[index]
    end

    def each(&block)
      @ranges.each(&block)
    end

    def merge
      return if @ranges.length <= 0

      @ranges.sort! { |a, b| a.first <=> b.first }
      new_ranges = [@ranges[0]]
      @ranges[1..-1].each do |range|
        if (new_ranges[-1].last > range.first || \
          new_ranges[-1].last == range.first) \
          && new_ranges[-1].last < range.last
          # merge
          new_ranges[-1] = new_ranges[-1].first..range.last
        elsif new_ranges[-1].last < range.first
          new_ranges << range
        end
      end

      @ranges = new_ranges
    end

    def -(other)
      merge
      other.merge
      difference = []
      each do |m|
        overlapped = false
        m_first = m.first
        other.each do |s|
          unless m_first > s.last || s.first > m.last
            overlapped = true
            if m_first < s.first
              m_addr = m_first
              # find previous ip of s.first
              while (m_addr_next = m_addr.next_ip(Objectify: true)) != s.first
                m_addr = m_addr_next
              end

              difference << (m_first.clone..m_addr.clone)
            end

            m_first = s.last.next_ip(Objectify: true)
            break if m_first > m.last
          end
        end

        unless (!overlapped || m_first > m.last) && overlapped
          difference << (m_first.clone..m.last.clone)
        end
      end

      difference
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
