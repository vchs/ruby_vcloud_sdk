require "spec_helper"
require_relative "mocks/client_response"
require_relative "mocks/response_mapping"
require "nokogiri/diff"

describe VCloudSdk::VDC do
  let(:conn) { double("Connection") }
  subject do
    vdc_response = VCloudSdk::Xml::WrapperFactory.wrap_document(
      VCloudSdk::Test::Response::VDC_RESPONSE)
    VCloudSdk::VDC.new(conn, vdc_response)
  end

  its(:storage_profiles) { should have_at_least(1).items }

  describe "#find_storage_profile_by_name" do
    it "return a storage profile given targeted name" do
      storage_profile = subject
        .find_storage_profile_by_name(VCloudSdk::Test::Response::STORAGE_PROFILE_NAME)
      storage_profile.should_not be_nil
    end

    it "return nil if targeted storage profile with given name does not exist" do
      storage_profile = subject.find_storage_profile_by_name("xxxxxxx")
      storage_profile.should be_nil
    end
  end
end
