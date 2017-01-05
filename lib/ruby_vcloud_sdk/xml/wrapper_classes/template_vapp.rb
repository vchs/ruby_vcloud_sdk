module VCloudSdk
  module Xml
    class TemplateVapp < Wrapper
      def vm_link
        get_nodes("Vm").first["href"]
      end
    end

  end
end
