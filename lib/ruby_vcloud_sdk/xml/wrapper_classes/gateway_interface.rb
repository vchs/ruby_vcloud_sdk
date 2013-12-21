module VCloudSdk
  module Xml
    class GatewayInterface < Wrapper
      def interface_type
        get_nodes(:InterfaceType, nil, true)
          .first
          .content
      end

      def subnet_participation
        get_nodes(:SubnetParticipation, nil, true)
          .first
      end

      def ip_ranges
        subnet_participation
          .get_nodes(:IpRanges, nil, true)
          .first
      end
    end
  end
end
