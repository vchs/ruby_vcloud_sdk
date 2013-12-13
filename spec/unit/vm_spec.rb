require "spec_helper"
require_relative "mocks/client_response"
require_relative "mocks/response_mapping"
require_relative "mocks/rest_client"
require "nokogiri/diff"

describe VCloudSdk::VM do

  let(:logger) { VCloudSdk::Test.logger }
  let(:url) { VCloudSdk::Test::Response::URL }
  let(:disk) do
    vdc_response = VCloudSdk::Xml::WrapperFactory.wrap_document(
      VCloudSdk::Test::Response::VDC_RESPONSE)

    disk_link = vdc_response
                  .disks(VCloudSdk::Test::Response::INDY_DISK_NAME)
    VCloudSdk::Disk.new(VCloudSdk::Test.mock_session(logger, url),
                        disk_link)
  end

  subject do
    described_class.new(VCloudSdk::Test.mock_session(logger, url),
                        VCloudSdk::Test::Response::INSTANTIATED_VM_LINK)
  end

  describe "#href" do
    it "returns the link of VM" do
      subject.href.should eql VCloudSdk::Test::Response::INSTANTIATED_VM_LINK
    end
  end

  describe "#name" do
    it "returns the name of VM" do
      subject.name.should eql VCloudSdk::Test::Response::VM_NAME
    end
  end

  describe "#independent_disks" do
    context "vm has attached disk" do
      it "returns a collection of disks" do
        VCloudSdk::Test::ResponseMapping.set_option vm_disk_attached: true
        disks = subject.independent_disks
        disks.should have(1).item
        disk = disks[0]
        disk.should be_an_instance_of VCloudSdk::Disk
        disk.name.should eql VCloudSdk::Test::Response::INDY_DISK_NAME
      end
    end

    context "vm has no attached disk" do
      before do
        VCloudSdk::Test::ResponseMapping.delete_option :vm_disk_attached
      end

      its(:independent_disks) { should eql [] }
    end
  end

  describe "#list_disks" do
    context "vm has attached disk" do
      before do
        VCloudSdk::Test::ResponseMapping.set_option vm_disk_attached: true
      end

      its(:list_disks) { should eql ["Hard disk 1", "Hard disk 2"] }
    end

    context "vm has no attached disk" do
      before do
        VCloudSdk::Test::ResponseMapping.delete_option :vm_disk_attached
      end

      its(:list_disks) { should eql ["Hard disk 1"] }
    end
  end

  describe "#attach_disk" do
    it "attaches the disk successfully" do
      attach_task = subject.attach_disk(disk)
      subject
        .send(:task_is_success, attach_task)
        .should be_true
    end

    context "error occurs when attaching disk" do
      it "raises the exception" do
        VCloudSdk::Connection::Connection
          .any_instance
          .should_receive(:post)
          .once
          .with(VCloudSdk::Test::Response::INSTANTIATED_VM_ATTACH_DISK_LINK,
                anything,
                VCloudSdk::Xml::MEDIA_TYPE[:DISK_ATTACH_DETACH_PARAMS])
          .and_raise RestClient::BadRequest

        expect do
          subject.attach_disk(disk)
        end.to raise_exception RestClient::BadRequest
      end
    end
  end

  describe "#detach_disk" do
    context "vApp is suspended" do
      it "raises VmSuspendedError" do
        VCloudSdk::Test::ResponseMapping
          .set_option vapp_power_state: :suspended

        expect do
          subject.detach_disk(disk)
        end.to raise_exception VCloudSdk::VmSuspendedError,
                               "vApp #{VCloudSdk::Test::Response::VAPP_NAME}" +
                               " suspended, discard state before detaching disk."
      end
    end

    context "vApp is powered on" do
      before do
        VCloudSdk::Test::ResponseMapping
          .set_option vapp_power_state: :on
      end

      it "detaches the disk successfully" do
        detach_task = subject.detach_disk(disk)
        subject
          .send(:task_is_success, detach_task)
          .should be_true
      end

      context "error occurs when attaching disk" do
        it "raises the exception" do
          VCloudSdk::Connection::Connection
            .any_instance
            .should_receive(:post)
            .once
            .with(VCloudSdk::Test::Response::INSTANTIATED_VM_DETACH_DISK_LINK,
                  anything,
                  VCloudSdk::Xml::MEDIA_TYPE[:DISK_ATTACH_DETACH_PARAMS])
            .and_raise RestClient::BadRequest

          expect do
            subject.detach_disk(disk)
          end.to raise_exception RestClient::BadRequest
        end
      end
    end
  end
end