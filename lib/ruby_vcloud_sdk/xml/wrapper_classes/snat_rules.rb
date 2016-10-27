module VCloudSdk
  module Xml
    class NatRule < Wrapper 
      
      def description=(desc)
          get_nodes("Description").first.content = desc
      end

      def rule_type=(type)
          get_nodes("RuleType").first.content = type
      end

      def enabled=(opt)
        get_nodes("IsEnabled").first.content = opt
      end

      def id=(id)
        get_nodes("Id").first.content = id
      end

      def interface=(interface)    
        get_nodes("Interface").first["type"] = interface.get_nodes("Network").first["type"]
        get_nodes("Interface").first["name"] = interface.get_nodes("Network").first["name"]
        get_nodes("Interface").first["href"] = interface.get_nodes("Network").first["href"]
      end
      
      def original_ip=(ip)
        get_nodes("OriginalIp").first.content = ip
      end

      def original_ip
        get_nodes("OriginalIp").first.content
      end
     
      def translated_ip=(ip)
        get_nodes("TranslatedIp").first.content = ip
      end

      def translated_ip
        get_nodes("TranslatedIp").first.content
      end
    end
  end
end