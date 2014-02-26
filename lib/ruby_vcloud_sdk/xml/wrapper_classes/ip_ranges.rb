module VCloudSdk
  module Xml
    class IpRanges < Wrapper
      def ranges
        get_nodes(:IpRange)
      end

      def add_ranges(ranges)
        ranges.each do |range|
          ip_range_node = add_child("IpRange")
          start_address = add_child("StartAddress",
                                    nil,
                                    nil,
                                    ip_range_node)
          start_address.content = range.start_address
          end_address = add_child("EndAddress",
                                  nil,
                                  nil,
                                  ip_range_node)
          end_address.content = range.end_address
        end
      end
    end
  end
end
