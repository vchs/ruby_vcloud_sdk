require_relative "vdc_storage_profile"

module VCloudSdk

  class VDC
    attr_reader :name

    def initialize(connection, vdc_xml_obj)
      @connection, @vdc_xml_obj = connection, vdc_xml_obj
      @name = vdc_xml_obj.name
    end

    def storage_profiles
      @vdc_xml_obj.storage_profiles.map do |storage_profile|
        VCloudSdk::VdcStorageProfile
          .new(@connection, storage_profile)
      end
    end

    # Return a storage profile given targeted name
    # Return nil if targeted storage profile with given name does not exist
    def find_storage_profile_by_name(name)
      storage_profiles.each do |storage_profile|
        return storage_profile if storage_profile.name == name
      end

      return nil
    end
  end
end
