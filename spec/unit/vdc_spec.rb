require "spec_helper"
require_relative "mocks/client_response"
require_relative "mocks/response_mapping"
require_relative "mocks/rest_client"
require "nokogiri/diff"

describe VCloudSdk::VDC do

  let(:logger) { VCloudSdk::Config.logger }
  let(:url) { VCloudSdk::Test::Response::URL }

  let(:mock_connection) do
    VCloudSdk::Test.mock_connection(logger, url)
  end

  subject do
    described_class.new(mock_connection, vdc_response)
  end

  describe "#storage_profiles" do
    let(:vdc_response) do
      VCloudSdk::Xml::WrapperFactory.wrap_document(
        VCloudSdk::Test::Response::VDC_RESPONSE)
    end

    its(:storage_profiles) { should have_at_least(1).item }
  end

  describe "#find_storage_profile_by_name" do
    let(:vdc_response) do
      VCloudSdk::Xml::WrapperFactory.wrap_document(
        VCloudSdk::Test::Response::VDC_RESPONSE)
    end

    it "return a storage profile given targeted name" do
      storage_profile = subject
        .find_storage_profile_by_name(VCloudSdk::Test::Response::STORAGE_PROFILE_NAME)
      storage_profile.name.should eql VCloudSdk::Test::Response::STORAGE_PROFILE_NAME
    end

    it "return nil if targeted storage profile with given name does not exist" do
      storage_profile = subject.find_storage_profile_by_name("xxxxxxx")
      storage_profile.should be_nil
    end
  end

  describe "#vapps" do
    context "vdc has vapps" do
      let(:vdc_response) do
        VCloudSdk::Xml::WrapperFactory.wrap_document(
          VCloudSdk::Test::Response::VDC_RESPONSE)
      end

      its(:vapps) { should have_at_least(1).item }
    end

    context "vdc has no vapps" do
      let(:vdc_response) do
        VCloudSdk::Xml::WrapperFactory.wrap_document(
          VCloudSdk::Test::Response::EMPTY_VDC_RESPONSE)
      end

      its(:vapps) { should have(0).item }
    end

  end
end
