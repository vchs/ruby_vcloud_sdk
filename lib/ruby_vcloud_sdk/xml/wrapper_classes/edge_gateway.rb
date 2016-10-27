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

      def add_fw_rules(rules)
        id = obtain_id("FirewallRule").nil? ? 1 : obtain_id("FirewallRule")       
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
            nm = get_nodes("FirewallRule").last.node
            nm.after(fw_rule.node) 
        end
        self
      end
      
      def remove_fw_rules(ips)
        rules = get_nodes("FirewallRule")
        rules.each do |rule|
          ips.each do |ip|                     
              rule.node.remove if rule.ip_dest == ip         
          end
        end
        self
      end

      def add_nat_rules(rules)
        id = obtain_id("NatRule").nil? ? 65537 : obtain_id("NatRule")
        rules.each do |rule|
            id = id + 1
            if rule[:rule_type] == "SNAT"
                snat_rule = Xml::WrapperFactory.create_instance("SNatRule").tap do |params|
                  params.id               = id.to_s
                  params.description      = rule[:description]
                  params.enabled          = rule[:enabled] 
                  params.rule_type        = rule[:rule_type]
                  params.interface        = gateway_interface_by_name(rule[:interface])
                  params.original_ip      = rule[:original_ip]       
                  params.translated_ip    = rule[:translated_ip]                  
                end
                nm = get_nodes("NatRule").last.node         
                nm.after(snat_rule.node)

            elsif rule[:rule_type] == "DNAT"
                dnat_rule = Xml::WrapperFactory.create_instance("DNatRule").tap do |params|
                  params.id               = id.to_s
                  params.description      = rule[:description]
                  params.enabled          = rule[:enabled] 
                  params.rule_type        = rule[:rule_type]
                  params.interface        = gateway_interface_by_name(rule[:interface])
                  params.original_ip      = rule[:original_ip]
                  params.original_port    = rule[:original_port]
                  params.translated_ip    = rule[:translated_ip]  
                  params.translated_port   = rule[:translated_port]
                  params.protocol         = rule[:protocol]      
                end
                nm = get_nodes("NatRule").last.node         
                nm.after(dnat_rule.node)
            end    
        end
        self
      end

      def remove_nat_rules(ips)
        rules = get_nodes("NatRule")
        rules.each do |rule|
          ips.each do |ip|                     
              rule.node.remove if rule.original_ip == ip or rule.translated_ip         
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

      private

      def obtain_id(tag)
        if get_nodes(tag).empty?
            id = nil
        else
            id = get_nodes(tag).last
                      .get_nodes("Id").first
                      .content.to_i
        end
        return id

      end

      def gateway_interface_by_name(name)
        gateway_interfaces.each do |gat_in|
          return gat_in if gat_in.get_nodes("Name").first.content == name
        end      
      end

    end
  end
end
