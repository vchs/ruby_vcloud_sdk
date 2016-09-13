module VCloudSdk
  module Xml
    class EdgeGateway < Wrapper
      def configure_services_link
         get_nodes(XML_TYPE[:LINK],
                  { rel: "edgeGateway:configureServices" },
                  true).first
      end
      def configure_services
         get_nodes("EdgeGatewayServiceConfiguration").first
      end

      def add_rules(rules)
        ###OBTAIN LAST ID
        id = get_nodes("FirewallRule").last
                      .get_nodes("Id").first
                      .content.to_i
        rules.each do |rule|
            id = id + 1
            fw_rule = Xml::WrapperFactory.create_instance("FirewallRule").tap do |params|
                params.id = id.to_s
                params.description = rule[:name]
                params.ips(rule[:ip_src],rule[:ip_dest])
                params.ports(rule[:port_src],rule[:port_dest])
                params.action = rule[:action]
                params.enabled = rule[:enabled]            
            end
            nm = @root.at_css "FirewallRule"
            nm.add_next_sibling "\n#{fw_rule}" 
        end
        self
      end
      
      def remove_rules(ips)
        rules = get_nodes("FirewallRule")
        rules.each do |rule|
          ips.each do |ip|                     
              rule.node.remove if rule.ip_dest == ip         
          end
        end
        self
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
