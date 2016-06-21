require_relative "vdc"
require_relative "catalog"
require_relative "session"
require_relative "infrastructure"
require_relative "right_record"

module VCloudSdk

  ################################################################################
  # This class represents a vCloud connection and an associated client
  # The connection is associated to the vCloud API. 
  ################################################################################
  class Client
    include Infrastructure

    VCLOUD_VERSION_NUMBER = "5.1"

    public :find_vdc_by_name, :catalogs, :list_catalogs,
           :catalog_exists?, :find_catalog_by_name,
           :vdc_exists?

    ##############################################################################
    # Initializes the Client and creates a Session to vCloud API. 
    # @param url      [String] The url of vCloud host [http://api.example.com]
    # @param username [String] The username of vCloud account [username@org_name]
    # @param password [String] The password for vCloud user.
    # @param options  [Hash]   The options (RETRIES, TIME_LIMIT_SEC,DELAY) for 
    #                          the session.Use 'options = {}' for default options.
    #                          See session.rb for more info.
    # @param logger   [Logger] Optional.The logger for the connection. It manages 
    #                          response messages.By default STDOUT 
    ##############################################################################
    def initialize(url, username, password, options = {}, logger = nil)
      @url = url
      Config.configure(logger: logger || Logger.new(STDOUT))

      @session = Session.new(url, username, password, options)
      Config.logger.info("Successfully connected.")
    end

    ##############################################################################
    # Creates a catalog for the organization. 
    # @param name        [String]   The catalog's name.
    # @param description [String]   The catalog's description.
    # @return            [Catalog]  The new created catalog.
    ##############################################################################
    def create_catalog(name, description = "")
      catalog = Xml::WrapperFactory.create_instance("AdminCatalog")
      catalog.name = name
      catalog.description = description
      connection.post("/api/admin/org/#{@session.org.href_id}/catalogs",
                      catalog,
                      Xml::ADMIN_MEDIA_TYPE[:CATALOG])
      find_catalog_by_name name
    end

    ##############################################################################
    # Deletes the catalog identified with "name" for the organization. 
    # @param name  [String]   The catalog's name to delete
    # @return      [Catalog]  The deleted catalog 
    ##############################################################################
    def delete_catalog_by_name(name)
      catalog = find_catalog_by_name(name)
      catalog.delete_all_items
      connection.delete("/api/admin/catalog/#{catalog.id}")
      self
    end

    ##############################################################################
    # Returns Right Records. 
    # @return [Right Record] an array of Right Record.
    ##############################################################################
    def right_records
      right_records = connection.get("/api/admin/rights/query").right_records

      right_records.map do |right_record|
        VCloudSdk::RightRecord.new(right_record)
      end
    end
  end

end
