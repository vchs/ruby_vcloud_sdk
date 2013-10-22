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
  end
end
