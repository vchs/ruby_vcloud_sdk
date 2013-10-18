module VCloudSdk

  class VDC
    def initialize(name, connection, vdc_xml_obj)
      @name, @connection, @vdc_xml_obj = name, connection, vdc_xml_obj
    end
  end
end
