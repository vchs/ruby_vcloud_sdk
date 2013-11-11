module VCloudSdk
  module Xml
    class IpRange < Wrapper
      def start_address
        get_nodes(:StartAddress).first.content
      end

      def end_address
        get_nodes(:EndAddress).first.content
      end
    end
  end
end
