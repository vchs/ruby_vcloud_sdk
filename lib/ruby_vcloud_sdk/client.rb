require_relative "vdc"
require_relative "catalog"
require_relative "session"
require_relative "infrastructure"

module VCloudSdk

  class Client
    include Infrastructure

    VCLOUD_VERSION_NUMBER = "5.1"

    RETRIES = {
      default: 5,
      upload_vapp_files: 7,
      cpi: 1,
    }

    TIME_LIMIT_SEC = {
      default: 120,
      delete_vapp_template: 120,
      delete_vapp: 120,
      delete_media: 120,
      instantiate_vapp_template: 300,
      power_on: 600,
      power_off: 600,
      undeploy: 720,
      process_descriptor_vapp_template: 300,
      http_request: 240,
    }

    REST_THROTTLE = {
      min: 0,
      max: 1,
    }

    private_constant :RETRIES, :TIME_LIMIT_SEC, :REST_THROTTLE

    def initialize(url, username, password, options = {}, logger = nil)
      @url = url
      @retries = options[:retries] || RETRIES
      @time_limit = options[:time_limit_sec] || TIME_LIMIT_SEC
      Config.configure(
          logger: logger || Logger.new(STDOUT),
          rest_throttle: options[:rest_throttle] || REST_THROTTLE)

      @connection = Connection::Connection.new(
          @url,
          @time_limit[:http_request])
      session_xml_obj = @connection.connect(username, password)
      @session = Session.new(session_xml_obj, @connection)
      Config.logger.info("Successfully connected.")
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
