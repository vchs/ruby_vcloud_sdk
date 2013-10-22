module VCloudSdk

  class VdcStorageProfile
    attr_reader :name

    def initialize(connection, storage_profile_xml_obj)
      @connection, @storage_profile_xml_obj =
        connection, storage_profile_xml_obj
      @name = storage_profile_xml_obj.name
    end

  end

end
