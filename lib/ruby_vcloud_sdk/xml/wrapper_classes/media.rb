module VCloudSdk
  module Xml
    class Media < Wrapper
      def size
        @root["size"]
      end

      def size=(size)
        @root["size"] = size.to_s
      end

      def image_type
        @root["imageType"]
      end

      def image_type=(image_type)
        @root["imageType"] = image_type.to_s
      end

      def storage_profile=(storage_profile)
        add_child(storage_profile) unless storage_profile.nil?
      end

      def files
        get_nodes("File")
      end

      # Files that haven"t finished transferring
      def incomplete_files
        files.select do |f|
          f["size"].to_i < 0 ||
          (f["size"].to_i > f["bytesTransferred"].to_i)
        end
      end

      def delete_link
        get_nodes(XML_TYPE[:LINK], { rel: XML_TYPE[:REMOVE] }, true).first
      end

      def running_tasks
        get_nodes("Task", status: TASK_STATUS[:RUNNING])
      end
    end
  end
end
