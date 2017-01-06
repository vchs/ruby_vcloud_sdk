module VCloudSdk
  module Xml

    class SourcedVmInstantiationParams < Wrapper
      def name
        @root["name"]
      end
      def resize_disk(id,size,vm_link)
      	disk_node = get_nodes("Source").first
        disk_node["href"] = vm_link
        disk_node = get_nodes("Disk").first
        disk_node["instanceId"] = "200#{id}"
        get_nodes("Size").first.content = size
      end
    end
  end
end