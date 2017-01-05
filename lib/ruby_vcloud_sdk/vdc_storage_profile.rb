module VCloudSdk

  class VdcStorageProfile
    attr_reader :name, :storage_used_mb, :storage_limit_mb

    def initialize(storage_profile_xml_obj)      
      @storage_profile_xml_obj = storage_profile_xml_obj
      @name = @storage_profile_xml_obj[:name]
      @storage_used_mb = @storage_profile_xml_obj[:storageUsedMB].to_i
      @storage_limit_mb = @storage_profile_xml_obj[:storageLimitMB].to_i
      @vdc_name = @storage_profile_xml_obj[:vdcName]
    end

    # Return storageLimitMB - storageUsedMB
    # Return -1 if 'storageLimitMB' is 0
    def available_storage
      return -1 if @storage_limit_mb == 0

      @storage_limit_mb - @storage_used_mb
    end
  end

end
