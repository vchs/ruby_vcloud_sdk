module VCloudSdk
  class VApp
    attr_reader :name

    def initialize(session, vapp_xml_obj)
      @session = session
      @vapp_xml_obj = vapp_xml_obj
      @name = @vapp_xml_obj.name
    end
  end
end
