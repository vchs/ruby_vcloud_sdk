require "spec_helper"
require_relative "mocks/client_response"
require_relative "mocks/response_mapping"
require_relative "mocks/rest_client"
require "nokogiri/diff"

describe VCloudSdk::VDC do

  let(:logger) { VCloudSdk::Config.logger }
  let(:url) { VCloudSdk::Test::Response::URL }

  let(:mock_session) do
    session = double("session")
    connection = VCloudSdk::Test.mock_connection(logger, url)
    session.stub(:connection).and_return(connection)
    session
  end

  subject do
    described_class.new(mock_session, vdc_response)
  end

  describe "#storage_profiles" do
    context "vdc has storage profiles" do
      let(:vdc_response) do
        VCloudSdk::Xml::WrapperFactory.wrap_document(
          VCloudSdk::Test::Response::VDC_RESPONSE)
      end

      before do
        VCloudSdk::Test::ResponseMapping.set_option storage_profile: :non_empty
      end

      context "vdc name contains no space" do
        its(:storage_profiles) { should have_at_least(1).item }
      end

      context "vdc name contains spaces" do
        before do
          subject.instance_variable_set(:@name, VCloudSdk::Test::Response::OVDC_NAME_WITH_SPACE)
        end

        its(:storage_profiles) { should have_at_least(1).item }
      end
    end

    context "vdc has no storage profile" do
      let(:vdc_response) do
        VCloudSdk::Xml::WrapperFactory.wrap_document(
          VCloudSdk::Test::Response::EMPTY_VDC_RESPONSE)
      end

      before do
        VCloudSdk::Test::ResponseMapping.set_option storage_profile: :empty
      end

      its(:storage_profiles) { should have(0).item }
    end
  end

  describe "#find_storage_profile_by_name" do
    let(:vdc_response) do
      VCloudSdk::Xml::WrapperFactory.wrap_document(
        VCloudSdk::Test::Response::VDC_RESPONSE)
    end

    it "return a storage profile given targeted name" do
      VCloudSdk::Test::ResponseMapping.set_option storage_profile: :non_empty
      storage_profile = subject
        .find_storage_profile_by_name(VCloudSdk::Test::Response::STORAGE_PROFILE_NAME)
      storage_profile.name.should eql VCloudSdk::Test::Response::STORAGE_PROFILE_NAME
    end

    it "return nil if targeted storage profile with given name does not exist" do
      VCloudSdk::Test::ResponseMapping.set_option storage_profile: :non_empty
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

  describe "#find_vapp_by_name" do
    let(:vdc_response) do
      VCloudSdk::Xml::WrapperFactory.wrap_document(
        VCloudSdk::Test::Response::VDC_RESPONSE)
    end

    it "returns a vapp given targeted name" do
      vapp = subject.find_vapp_by_name(VCloudSdk::Test::Response::EXISTING_VAPP_NAME)
      vapp.name.should eql VCloudSdk::Test::Response::EXISTING_VAPP_NAME
    end

    it "returns nil if targeted vapp with given name does not exist" do
      vapp = subject.find_vapp_by_name("xxxxxxx")
      vapp.should be_nil
    end
  end
end
