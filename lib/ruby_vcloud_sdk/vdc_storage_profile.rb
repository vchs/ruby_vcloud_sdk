module VCloudSdk

  class VdcStorageProfile
    attr_reader :name

    def initialize(connection, storage_profile_xml_obj)
      @connection, @storage_profile_xml_obj =
        connection, storage_profile_xml_obj
      @name = storage_profile_xml_obj[:name]
      @storage_used_mb = storage_profile_xml_obj[:storageUsedMB].to_i
      @storage_limit_mb = storage_profile_xml_obj[:storageLimitMB].to_i
      @vdc_name = storage_profile_xml_obj[:vdcName]
    end

  end

end
