module VCloudSdk
  module Xml
    class EdgeGateway < Wrapper
      def configure_services_link
         get_nodes(XML_TYPE[:LINK],
                  { rel: "edgeGateway:configureServices" },
                  true).first
      end

      def add_rule(options)
        ###NEXT ID
        id = get_nodes("FirewallRule").last
                      .get_nodes("Id").first
                      .content.to_i + 1

    
      end
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
