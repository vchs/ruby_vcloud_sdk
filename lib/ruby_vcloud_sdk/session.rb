module VCloudSdk
  class Session
    attr_reader :connection
    attr_accessor :retries, :time_limit, :delay

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

    DELAY = 1

    private_constant :RETRIES, :TIME_LIMIT_SEC, :DELAY

    def initialize(url, username, password, options)
      @time_limit = options[:time_limit_sec] || TIME_LIMIT_SEC
      @retries = options[:retries] || RETRIES
      @delay = options[:delay] || DELAY
      @connection = Connection::Connection.new(
        url,
        @time_limit[:http_request])
      @session_xml_obj = @connection.connect(username, password)
      @org_link = @session_xml_obj.organization
    end

    def org
      @connection.get(@org_link)
    end

  end
end
