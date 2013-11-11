module VCloudSdk
  module Xml
    class IpRanges < Wrapper
      def ip_range
        get_nodes(:IpRange)
      end
    end
  end
end
