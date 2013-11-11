module VCloudSdk
  module Xml
    class OrgVdcNetwork < Wrapper
      def ip_scope
        get_nodes(:IpScope).first
      end

      def ip_ranges
        get_nodes(:IpRanges).first
      end
    end
  end
end
