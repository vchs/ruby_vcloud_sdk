module VCloudSdk
  module Xml
    class EdgeGateway < Wrapper
      def gateway_interfaces
        get_nodes(:Configuration, nil, true)
          .first
          .get_nodes(:GatewayInterfaces, nil, true)
          .first
          .get_nodes(:GatewayInterface, nil, true)
      end
    end
  end
end
