module VCloudSdk
  module Xml
    class GuestCustomizationSection < Wrapper 
      def href=(value)
        @root["href"] = value
      end

      def type=(value)
        @root["type"] = value
      end

      def enable(uuid=nil)
        get_nodes("Enabled").first.content = true
        get_nodes("VirtualMachineId").first.content = uuid
      end

      def computer_name=(value)
        get_nodes("ComputerName").first.content = value
      end

      def change_sid=(value)
        get_nodes("ChangeSid").first.content = value
      end

      def admin_pass=(value)
        get_nodes("AdminPasswordEnabled").first.content = true
        get_nodes("AdminPasswordAuto").first.content    = false
     
        if get_nodes("AdminPassword").first.nil?
          nm = get_nodes("AdminPasswordAuto").last.node
          nm.after("<AdminPassword>#{value}</AdminPassword>")
        else
          get_nodes("AdminPassword").first.content        = value 
        end 

      end

      def auto_password=(value)
        get_nodes("AdminPasswordEnabled").first.content = true
        get_nodes("AdminPasswordAuto").first.content = value
      end

      def reset_pass=(value)
        get_nodes("ResetPasswordRequired").first.content = value
      end

      def script=(value)
        if get_nodes("CustomizationScript").first.nil?
          nm = get_nodes("ResetPasswordRequired").last.node
          nm.after("<CustomizationScript>#{value}</CustomizationScript>")
        else 
          get_nodes("CustomizationScript").first.content        = value 

        end
      end
    end
  end
end
