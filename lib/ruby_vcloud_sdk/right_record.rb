module VCloudSdk

  class RightRecord
    attr_reader :name, :category

    def initialize(right_record_xml_obj)
      @right_record_xml_obj = right_record_xml_obj
      @name = right_record_xml_obj[:name]
      @category = right_record_xml_obj[:category]
    end
  end
end
