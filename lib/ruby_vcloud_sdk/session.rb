module VCloudSdk
  class Session
    attr_reader :connection

    def initialize(session_xml_obj, connection)
      @session_xml_obj = session_xml_obj
      @org_link = @session_xml_obj.organization
      @connection = connection
    end

    def org
      @connection.get(@org_link)
    end

  end
end
