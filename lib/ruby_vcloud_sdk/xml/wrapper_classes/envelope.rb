module VCloudSdk
  module Xml
    class Envelope < Wrapper        
      def operating_system 
        get_nodes("OperatingSystemSection", nil, false, OVF).first.
                get_nodes("Description",nil,false,OVF).first.content      
      end

      def hardware_section
         get_nodes("VirtualHardwareSection",nil,false,OVF).first
      end 
    end     
  end
end
