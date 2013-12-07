module VCloudSdk
  module Xml
    class Disk < Wrapper
      def bus_type
        @root["busType"]
      end

      def bus_type=(value)
        @root["busType"] = value.to_s
      end

      def bus_sub_type
        @root["busSubType"]
      end

      def bus_sub_type=(value)
        @root["busSubType"] = value.to_s
      end

      def size_mb
        @root["size"].to_i / 1024 / 1024
      end

      def running_tasks
        tasks.select { |t| RUNNING.include?(t.status) }
      end

      def tasks
        get_nodes(XML_TYPE[:TASK])
      end

      def status
        @root["status"]
      end

      private

      RUNNING = [TASK_STATUS[:RUNNING],
                 TASK_STATUS[:QUEUED],
                 TASK_STATUS[:PRE_RUNNING]]
    end
  end
end
