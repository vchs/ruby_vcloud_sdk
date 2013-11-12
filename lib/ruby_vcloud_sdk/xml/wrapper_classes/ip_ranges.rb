module VCloudSdk
  module Xml
    class IpRanges < Wrapper
      def ranges
        get_nodes(:IpRange)
      end
    end
  end
end
