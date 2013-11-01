require "uri"
require_relative "vdc_storage_profile"
require_relative "vapp"

module VCloudSdk

  class VDC
    attr_reader :name

    def initialize(session, vdc_xml_obj)
      @vdc_xml_obj = vdc_xml_obj
      @connection = session.connection
      @name = vdc_xml_obj.name
    end

    def storage_profiles
      @connection.get("/api/query?type=orgVdcStorageProfile&filter=vdcName==#{URI.encode(@name)}")
        .org_vdc_storage_profile_records.map do |storage_profile|
          VCloudSdk::VdcStorageProfile.new(storage_profile)
        end
    end

    def find_storage_profile_by_name(name)
      storage_profiles.each do |storage_profile|
        return storage_profile if storage_profile.name == name
      end

      nil
    end

    def vapps
      @vdc_xml_obj.vapps.map do |vapp|
        VCloudSdk::VApp.new(@connection, vapp)
      end
    end

    def find_vapp_by_name(name)
      vapps.each do |vapp|
        return vapp if vapp.name == name
      end

      nil
    end
  end
end
