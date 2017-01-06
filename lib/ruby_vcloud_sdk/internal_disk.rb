module VCloudSdk

  class InternalDisk
    attr_reader :id, :name, :capacity, :bus_type, :bus_sub_type

    def initialize(entity_xml)
      @id = entity_xml.disk_id
      @name = entity_xml.element_name
      @capacity = entity_xml.host_resource.attribute("capacity").to_s.to_i
      @bus_type = entity_xml.host_resource.attribute("busType").to_s
      @bus_sub_type = entity_xml.host_resource.attribute("busSubType").to_s
    end
  end
end
