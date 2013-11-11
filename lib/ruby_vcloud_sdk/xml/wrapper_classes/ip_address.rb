module VCloudSdk
  module Xml
    class IpAddress < Wrapper
      def ip_address
        get_nodes(:IpAddress, nil, true)
          .first.content
      end
    end
  end
end
