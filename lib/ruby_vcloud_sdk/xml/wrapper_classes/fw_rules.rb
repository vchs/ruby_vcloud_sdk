module VCloudSdk
  module Xml
    class FirewallRule < Wrapper 
      def href=(value)
        @root["href"] = value
      end

      def type=(value)
        @root["type"] = value
      end

      def id=(id)
        get_nodes("Id").first.content = id
      end

      def ip_dest
        get_nodes("DestinationIp").first.content
      end

      def enabled=(opt)
        get_nodes("IsEnabled").first.content = opt
      end

      def description=(desc)
        get_nodes("Description").first.content = desc
      end

      def ips(src,dest)
        get_nodes("SourceIp").first.content       = src
        get_nodes("DestinationIp").first.content  = dest
      end

      def ports(src,dest)
        if dest == "Any"
            get_nodes("Port").first.content                 = "-1"
        else
            get_nodes("Port").first.content                 = dest
        end
        get_nodes("SourcePort").first.content           = "-1" if src == "Any"
        get_nodes("SourcePortRange").first.content      = src
        get_nodes("DestinationPortRange").first.content = dest    
      end

      def action=(act)
        get_nodes("Policy").first.content = act
      end
      
    end
  end
end