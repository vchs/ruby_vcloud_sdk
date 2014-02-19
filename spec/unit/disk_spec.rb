require "spec_helper"
require_relative "mocks/client_response"
require_relative "mocks/response_mapping"
require_relative "mocks/rest_client"
require "nokogiri/diff"
require "ruby_vcloud_sdk/disk"

describe VCloudSdk::Disk do

  let(:logger) { VCloudSdk::Test.logger }
  let(:url) { VCloudSdk::Test::Response::URL }
  let(:disk_name) { VCloudSdk::Test::Response::INDY_DISK_NAME }

  subject do
    vdc_response = VCloudSdk::Xml::WrapperFactory.wrap_document(
      VCloudSdk::Test::Response::VDC_RESPONSE)

    disk_link = vdc_response
                  .disks(disk_name)
    described_class.new(VCloudSdk::Test.mock_session(logger, url),
                        disk_link.href)
  end

  describe "#name" do
    it "returns the name of disk" do
      subject.name.should eql disk_name
    end
  end

  describe "#bus_type" do
    it "returns the bus_type of disk" do
      subject.bus_type.should eql "6"
    end
  end

  describe "#bus_sub_type" do
    it "returns the bus_sub_type of disk" do
      subject.bus_sub_type.should eql "lsilogic"
    end
  end

  describe "#size_mb" do
    it "returns the size in mb of disk" do
      subject.size_mb.should eql VCloudSdk::Test::Response::INDY_DISK_SIZE
    end
  end

  describe "#status" do
    it "returns the status of disk" do
      subject.status.should eql "1"
    end
  end

  describe "#attached?" do
    context "disk is attached to VM" do
      it "returns true" do
        VCloudSdk::Test::ResponseMapping
          .set_option disk_state: :attached
        subject.should be_attached
      end
    end

    context "disk is not attached to VM" do
      it "returns false" do
        VCloudSdk::Test::ResponseMapping
          .set_option disk_state: :not_attached
        subject.should_not be_attached
      end
    end
  end

  describe "#vm" do
    context "disk is attached to VM" do
      it "returns vm that the disk is attached to" do
        VCloudSdk::Test::ResponseMapping
          .set_option disk_state: :attached
        subject.vm.name.should eql VCloudSdk::Test::Response::VM_NAME
      end
    end

    context "disk is not attached to VM" do
      it "raises ObjectNotFoundError" do
        VCloudSdk::Test::ResponseMapping
          .set_option disk_state: :not_attached
        expect do
          subject.vm
        end.to raise_exception VCloudSdk::ObjectNotFoundError,
                               "No vm is attached to disk '#{disk_name}'"
      end
    end
  end
end
