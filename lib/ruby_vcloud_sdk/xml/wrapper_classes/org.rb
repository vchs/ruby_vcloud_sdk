module VCloudSdk
  module Xml
    class Org < Wrapper
      def vdc_link(name)
        get_nodes(XML_TYPE[:LINK],
                  { type: MEDIA_TYPE[:VDC],
                    name: name },
                  true).first
      end

      def catalogs
        get_nodes(XML_TYPE[:LINK],
                  { type: MEDIA_TYPE[:CATALOG] },
                  true)
      end

      def catalog_link(name)
        get_nodes(XML_TYPE[:LINK],
                  { type: MEDIA_TYPE[:CATALOG],
                    name: name },
                  true).first
      end

      def networks
        get_nodes(XML_TYPE[:LINK],
                  { type: MEDIA_TYPE[:ORG_NETWORK] },
                  true)
      end

      def network(name)
        get_nodes(XML_TYPE[:LINK],
                  { type: MEDIA_TYPE[:ORG_NETWORK],
                    name: name },
                  true).first
      end

      def disks
        get_nodes(XML_TYPE[:LINK],
                  { type: MEDIA_TYPE[:DISK] },
                  true)
      end
    end
  end
end
