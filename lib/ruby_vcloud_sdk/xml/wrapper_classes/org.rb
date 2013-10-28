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

      def catalog_link(name)
        get_nodes("Link",
                  { "type" => MEDIA_TYPE[:CATALOG],
                    "name" => name },
                  true).first
      end

      def id
        # Sample href: "https://10.146.21.135/api/org/a3783d64-0b9b-42d6-93cf-23bb08ec5520"
        URI.parse(href).path.split('/')[-1]
      end

    end

  end
end
