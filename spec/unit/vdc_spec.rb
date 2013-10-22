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

  describe "#storage_profiles" do
    it "give available storage profiles" do
      storage_profiles = subject.storage_profiles
      storage_profiles.length.should >= 1
    end
  end
end
