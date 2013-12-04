module VCloudSdk
  module Xml
    class Link < Wrapper
      def rel
        @root["rel"]
      end

      def rel=(rel)
        @root["rel"] = rel
      end
    end
  end
end

