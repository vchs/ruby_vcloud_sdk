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

    def add(ip_ranges, merge_ranges = true)
      ip_ranges = IpRanges.new(ip_ranges) if ip_ranges.is_a? String
      fail "Unable to parse object that is not IpRange or string" \
        unless ip_ranges.is_a? IpRanges
      @ranges += ip_ranges.ranges
      merge if merge_ranges
      @ranges
    end

    alias :+ :add

    def include?(ip_ranges)
      ip_ranges = IpRanges.new(ip_ranges) if ip_ranges.is_a? String
      @ranges.each do |v|
        ip_ranges.ranges.each do |o|
          return false if v.first > o.first || o.last > v.last
        end
      end

      true
    end

    def remove(other)
      difference = nil
      @ranges.each do |minuend|
        overlapped = false
        m_first = minuend.first
        other.ranges.each do |subtrahend|
          break if subtrahend.first > minuend.last
          unless m_first > subtrahend.last || subtrahend.first > minuend.last
            overlapped = true
            if m_first < subtrahend.first
              m_addr = m_first
              # find previous ip of s.first
              while (m_addr_next = m_addr.next_ip(Objectify: true)) != subtrahend.first
                m_addr = m_addr_next
              end

              difference = add_range difference, "#{m_first.ip}-#{m_addr.ip}"
            end

            m_first = subtrahend.last.next_ip(Objectify: true)
          end
        end

        unless (!overlapped || m_first > minuend.last) && overlapped
          difference = add_range difference, "#{m_first.ip}-#{minuend.last.ip}"
        end
      end

      difference
    end

    alias :- :remove

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

    def merge
      return if @ranges.length <= 0

      @ranges.sort! { |a, b| a.first <=> b.first }
      new_ranges = [@ranges[0]]
      @ranges[1..-1].each do |range|
        if new_ranges[-1].cover?(range.first)
          # merge
          new_range_last = [new_ranges[-1].last, range.last].max
          new_ranges[-1] = new_ranges[-1].first..new_range_last
        elsif new_ranges[-1].last < range.first
          new_ranges << range
        end
      end

      @ranges = new_ranges
    end

    def add_range(ip_ranges, range_to_add)
      if ip_ranges.nil?
        ip_ranges = IpRanges.new(range_to_add)
      else
        ip_ranges.add range_to_add, false
      end

      ip_ranges
    end
  end
end
