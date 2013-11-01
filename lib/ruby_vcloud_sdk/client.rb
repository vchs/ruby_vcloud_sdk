require "rest_client" # Need this for the exception classes
require "set"
require_relative "vdc"
require_relative "catalog"
require_relative "session"

module VCloudSdk

  class Client
    attr_reader :vdc

    VCLOUD_VERSION_NUMBER = "5.1"

    def initialize(url, username, password, options = {}, logger = nil)
      @url = url
      Config.configure(logger: logger || Logger.new(STDOUT))

      @session = Session.new(url, username, password, options)
      @connection = @session.connection
      Config.logger.info("Successfully connected.")
    end

    def find_vdc_by_name(name)
      vdc_link = @session.org.vdc_link(name)
      fail ObjectNotFoundError, "VDC #{name} not found" unless vdc_link
      VCloudSdk::VDC.new(@session, @connection.get(vdc_link))
    end

    def catalogs
      @session.org.catalogs.map do |catalog|
        VCloudSdk::Catalog.new(@session, catalog)
      end
    end

    def find_catalog_by_name(name)
      catalogs.each do |catalog|
        return catalog if catalog.name == name
      end

      nil
    end

    def create_catalog(name, description = "")
      catalog = Xml::WrapperFactory.create_instance("AdminCatalog")
      catalog.name = name
      catalog.description = description
      @connection.post("/api/admin/org/#{@session.org.href_id}/catalogs",
                       catalog,
                       Xml::ADMIN_MEDIA_TYPE[:CATALOG])
    end

    def delete_catalog(name)
      catalog = find_catalog_by_name(name)
      fail ObjectNotFoundError, "Catalog #{name} not found" unless catalog
      catalog.delete_all_catalog_items
      @connection.delete("/api/admin/catalog/#{catalog.id}")
    end
  end

end
