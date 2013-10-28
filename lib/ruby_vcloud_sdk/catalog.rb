module VCloudSdk

  class Catalog
    attr_reader :name

    def initialize(catalog_xml_obj)
      @catalog_xml_obj = catalog_xml_obj
      @name = catalog_xml_obj.name
    end

    def id
      @catalog_xml_obj.href_id
    end

  end
end
