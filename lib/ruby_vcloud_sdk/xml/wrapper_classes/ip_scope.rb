module VCloudSdk
  module Xml
    class IpScope < Wrapper
      def is_inherited?
        get_nodes(:IsInherited).first.content
      end

      def is_inherited=(value)
        get_nodes(:IsInherited).first.content = value
      end

      def gateway
        get_nodes(:Gateway).first.content
      end

      def gateway=(value)
        get_nodes(:Gateway).first.content = value
      end

      def netmask
        get_nodes(:Netmask).first.content
      end

      def netmask=(value)
        get_nodes(:Netmask).first.content = value
      end
    end
  end
end
