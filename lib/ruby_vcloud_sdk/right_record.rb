module VCloudSdk

  class RightRecord
    attr_reader :name

    def initialize(right_record_xml_obj)
      @right_record_xml_obj = right_record_xml_obj
      @name = right_record_xml_obj[:name]
    end
  end
end
