module VCloudSdk
  class VApp
    attr_reader :name

    def initialize(connection, vapp_xml_obj)
      @connection = connection
      @vapp_xml_obj = vapp_xml_obj
      @name = @vapp_xml_obj.name
    end
  end
end
