require "spec_helper"
require_relative "mocks/client_response"
require_relative "mocks/response_mapping"
require_relative "mocks/rest_client"
require "nokogiri/diff"

describe VCloudSdk::VDC do

  let(:logger) { VCloudSdk::Test.logger }
  let(:url) { VCloudSdk::Test::Response::URL }

  subject do
    described_class.new(VCloudSdk::Test.mock_session(logger, url),
                        vdc_response)
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
      vapp = subject.find_vapp_by_name(VCloudSdk::Test::Response::VAPP_NAME)
      vapp.name.should eql VCloudSdk::Test::Response::VAPP_NAME
    end

    it "raises an error if targeted vapp with given name does not exist" do
      expect do
        subject.find_vapp_by_name("xxxx")
      end.to raise_exception VCloudSdk::ObjectNotFoundError
                             "VApp 'xxxx' is not found"
    end
  end

  describe "#resources" do
    context "Cpu clock speed limit is greater than 0" do
      let(:vdc_response) do
        VCloudSdk::Xml::WrapperFactory.wrap_document(
            VCloudSdk::Test::Response::VDC_RESPONSE)
      end

      it "returns limit - used" do
        subject.resources.cpu.available_cores.should eq 4
      end
    end

    context "Cpu clock speed limit is 0" do
      let(:vdc_response) do
        VCloudSdk::Xml::WrapperFactory.wrap_document(
            VCloudSdk::Test::Response::EMPTY_VDC_RESPONSE)
      end

      it "returns -1" do
        subject.resources.cpu.available_cores.should eq(-1)
      end
    end

    context "Memory limit is greater than 0" do
      let(:vdc_response) do
        VCloudSdk::Xml::WrapperFactory.wrap_document(
            VCloudSdk::Test::Response::VDC_RESPONSE)
      end

      it "returns limit - used" do
        subject.resources.memory.available_mb.should eq 4096
      end
    end

    context "limit cpu clock speed is 0" do
      let(:vdc_response) do
        VCloudSdk::Xml::WrapperFactory.wrap_document(
            VCloudSdk::Test::Response::EMPTY_VDC_RESPONSE)
      end

      it "returns -1" do
        subject.resources.memory.available_mb.should eq(-1)
      end
    end
  end

  describe "#networks" do
    let(:vdc_response) do
      VCloudSdk::Xml::WrapperFactory.wrap_document(
        VCloudSdk::Test::Response::VDC_RESPONSE)
    end

    its(:networks) { should have_at_least(1).item }
  end

  describe "#find_network_by_name" do
    let(:vdc_response) do
      VCloudSdk::Xml::WrapperFactory.wrap_document(
        VCloudSdk::Test::Response::VDC_RESPONSE)
    end

    it "returns a network given targeted name" do
      network = subject
      .find_network_by_name(
        VCloudSdk::Test::Response::ORG_NETWORK_NAME)
      network.name.should eql VCloudSdk::Test::Response::ORG_NETWORK_NAME
    end

    it "returns nil if targeted network with given name does not exist" do
      network = subject.find_network_by_name("xxxxxxx")
      network.should be_nil
    end
  end

  describe "#disks" do
    context "vdc has disks" do
      let(:vdc_response) do
        VCloudSdk::Xml::WrapperFactory.wrap_document(
          VCloudSdk::Test::Response::VDC_RESPONSE)
      end

      it "returns a collection of disks" do
        disks = subject.disks
        disks.should have(1).item
        disk = disks[0]
        disk.should be_an_instance_of VCloudSdk::Disk
        disk.name.should eql VCloudSdk::Test::Response::INDY_DISK_NAME
      end
    end

    context "vdc has disks" do
      let(:vdc_response) do
        VCloudSdk::Xml::WrapperFactory.wrap_document(
          VCloudSdk::Test::Response::EMPTY_VDC_RESPONSE)
      end

      its(:disks) { should have(0).item }
    end
  end
end
