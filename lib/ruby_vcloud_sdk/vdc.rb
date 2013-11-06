require "forwardable"
require "uri"
require_relative "vdc_storage_profile"
require_relative "vapp"
require_relative "infrastructure"

module VCloudSdk

  class VDC
    include Infrastructure
    extend Forwardable
    attr_reader :name

    def_delegators :@vdc_xml_obj, :upload_link, :name

    def initialize(session, vdc_xml_obj)
      @session = session
      @vdc_xml_obj = vdc_xml_obj
    end

    public :storage_profiles, :find_storage_profile_by_name, :vapps, :find_vapp_by_name
  end
end
