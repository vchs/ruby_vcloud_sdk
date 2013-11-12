module VCloudSdk
  module Xml
    class OrgVdcNetwork < Wrapper
      def ip_scope
        get_nodes(:IpScope).first
      end

      def ip_ranges
        get_nodes(:IpRanges).first
      end

      def allocated_addresses_link
        get_nodes(XML_TYPE[:LINK],
                  { type: MEDIA_TYPE[:ALLOCATED_NETWORK_IPS] },
                  true).first
      end
    end
  end
end
