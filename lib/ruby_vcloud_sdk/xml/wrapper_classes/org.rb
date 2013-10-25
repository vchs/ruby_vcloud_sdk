module VCloudSdk
  module Xml

    class Org < Wrapper
      def vdc_link(name)
        get_nodes("Link",
                  { "type" => MEDIA_TYPE[:VDC],
                    "name" => name },
                  true).first
      end

      def catalogs
        get_nodes("Link",
                  { "type" => MEDIA_TYPE[:CATALOG] },
                  true)
      end

    end

  end
end
