module VCloudSdk
  module Xml
    class AllocatedIpAddresses < Wrapper
      def ip_addresses
        get_nodes(:IpAddress, nil, true)
      end
    end
  end
end
