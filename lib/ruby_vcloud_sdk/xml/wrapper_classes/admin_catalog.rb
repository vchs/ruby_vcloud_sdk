module VCloudSdk
  module Xml

    class AdminCatalog < Wrapper
      def description
        get_nodes("Description").first
      end

      def description=(desc)
        description.content = desc
      end

      def add_item_link
        get_nodes(XML_TYPE[:LINK],
                  { type: ADMIN_MEDIA_TYPE[:CATALOG_ITEM],
                    rel: XML_TYPE[:ADD] }).first
      end

      def catalog_items(name = nil)
        if name
          get_nodes(XML_TYPE[:CATALOGITEM], { name: name })
        else
          get_nodes(XML_TYPE[:CATALOGITEM])
        end
      end
    end

  end
end
