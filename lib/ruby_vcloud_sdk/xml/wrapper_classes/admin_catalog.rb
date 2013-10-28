module VCloudSdk
  module Xml

    class AdminCatalog < Wrapper
      def description
        get_nodes("Description").first
      end

      def name=(name)
        @root["name"] = name
      end

      def description=(desc)
        description.content = desc
      end

      def add_item_link
        get_nodes("Link", {"type"=>ADMIN_MEDIA_TYPE[:CATALOG_ITEM],
          "rel"=>"add"}).first
      end

      def catalog_items(name = nil)
        if name
          get_nodes("CatalogItem", {"name" => name})
        else
          get_nodes("CatalogItem")
        end
      end
    end

  end
end
