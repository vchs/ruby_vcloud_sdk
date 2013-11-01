require_relative "vdc"
require_relative "catalog"
require_relative "session"
require_relative "infrastructure"

module VCloudSdk

  class Client
    include Infrastructure

    VCLOUD_VERSION_NUMBER = "5.1"

    def initialize(url, username, password, options = {}, logger = nil)
      @url = url
      Config.configure(logger: logger || Logger.new(STDOUT))

      @session = Session.new(url, username, password, options)
      Config.logger.info("Successfully connected.")
    end

    def create_catalog(name, description = "")
      catalog = Xml::WrapperFactory.create_instance("AdminCatalog")
      catalog.name = name
      catalog.description = description
      connection.post("/api/admin/org/#{@session.org.href_id}/catalogs",
                       catalog,
                       Xml::ADMIN_MEDIA_TYPE[:CATALOG])
    end

    def delete_catalog(name)
      catalog = find_catalog_by_name(name)
      fail ObjectNotFoundError, "Catalog #{name} not found" unless catalog
      catalog.delete_all_catalog_items
      connection.delete("/api/admin/catalog/#{catalog.id}")
    end
  end

end
