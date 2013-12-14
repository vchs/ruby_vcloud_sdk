module VCloudSdk
  module Xml
    class Vms < Wrapper
      def vm_reference
        get_nodes("VmReference",
                  { type: MEDIA_TYPE[:VM] },
                  true)
                  .first
      end
    end
  end
end
