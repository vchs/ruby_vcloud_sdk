require "spec_helper"
require_relative "mocks/client_response"
require_relative "mocks/response_mapping"
require_relative "mocks/rest_client"
require "nokogiri/diff"
require "ruby_vcloud_sdk/disk"

describe VCloudSdk::Disk do

  let(:logger) { VCloudSdk::Test.logger }
  let(:url) { VCloudSdk::Test::Response::URL }

  subject do
    vdc_response = VCloudSdk::Xml::WrapperFactory.wrap_document(
      VCloudSdk::Test::Response::VDC_RESPONSE)

    disk_link = vdc_response
                  .disks(VCloudSdk::Test::Response::INDY_DISK_NAME)
    described_class.new(VCloudSdk::Test.mock_session(logger, url),
                        disk_link)
  end

  describe "#name" do
    it "returns the name of disk" do
      subject.name.should eql VCloudSdk::Test::Response::INDY_DISK_NAME
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

  describe "#delete" do
    it "deletes the disk successfully" do
      deletion_task = subject.delete
      subject
        .send(:task_is_success, deletion_task)
        .should be_true
    end

    context "error occurs when deleting disk" do
      it "raises the exception" do
        VCloudSdk::Connection::Connection
          .any_instance
          .should_receive(:delete)
          .once
          .with(VCloudSdk::Test::Response::INDY_DISK_URL)
          .and_raise RestClient::BadRequest

        expect do
          subject.delete
        end.to raise_exception RestClient::BadRequest
      end
    end
  end
end
