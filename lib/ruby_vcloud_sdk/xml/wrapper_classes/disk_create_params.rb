module VCloudSdk
  module Xml
    class DiskCreateParams < Wrapper
      def bus_type=(value)
        disk["busType"] = value.to_s
      end

      def bus_sub_type=(value)
        disk["busSubType"] = value.to_s
      end

      def name=(name)
        disk["name"] = name.to_s
      end

      def size_bytes=(value)
        disk["size"] = value.to_s
      end

      def add_locality(local)
        if !@local_exists.nil? && @local_exists
          fail "Cannot add locality more than once to DiskCreateParams"
        end
        @local_exists = true
        node = create_child("Locality")
        node["href"] = local.href
        # Bug in create independent disk API.  It needs the UUID part of the
        # ID instead of the entire ID like other REST API calls.
        node["id"] = extract_uuid(local.urn)
        node["type"] = MEDIA_TYPE[:VM]
        disk.node.after(node)
      end

      def add_storage_profile(storage_profile)
        node = create_child("StorageProfile")
        node["href"] = storage_profile.href
        node["name"] = storage_profile.name
        disk.node.add_child(node)
      end
      private

      def disk
        get_nodes("Disk").first
      end

      def extract_uuid(id)
        id.split(":").first
      end
    end
  end
end
