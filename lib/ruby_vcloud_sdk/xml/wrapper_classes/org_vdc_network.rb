module VCloudSdk
  module Xml
    class OrgVdcNetwork < Wrapper
      def ip_scope
        get_nodes(:IpScope).first
      end

      def allocated_addresses_link
        get_nodes(XML_TYPE[:LINK],
                  { type: MEDIA_TYPE[:ALLOCATED_NETWORK_IPS] },
                  true).first
      end

      def description
        get_nodes("Description").first.content        
      end

      def gateway
        get_nodes(:IpScope).first.
          get_nodes("Gateway").first.content
      end

      def netmask
        get_nodes(:IpScope).first.
          get_nodes("Netmask").first.content
      end

      def fence_mode
        get_nodes("FenceMode").first.content
      end
    end
  end
end
