require "spec_helper"
require_relative "mocks/client_response"
require_relative "mocks/response_mapping"
require_relative "mocks/rest_client"
require "rest_client"
require "nokogiri/diff"
require "ruby_vcloud_sdk/xml/wrapper_classes/vapp"

describe VCloudSdk::VApp do

  let(:logger) { VCloudSdk::Test.logger }
  let(:url) { VCloudSdk::Test::Response::URL }
  let(:vapp_name) { VCloudSdk::Test::Response::VAPP_NAME }
  let(:catalog_name) { VCloudSdk::Test::Response::CATALOG_NAME }
  let(:network_name) { VCloudSdk::Test::Response::ORG_NETWORK_NAME }

  subject do
    vdc_response = VCloudSdk::Xml::WrapperFactory.wrap_document(
      VCloudSdk::Test::Response::VDC_RESPONSE)
    described_class.new(VCloudSdk::Test.mock_session(logger, url),
                        vdc_response.vapps.first)
  end

  describe "#initialize" do
    it "initializes successfully" do
      subject.name.should eql vapp_name
    end
  end

  describe "#delete" do

    before do
      VCloudSdk::Test::ResponseMapping
        .set_option delete_vapp_task_state: :running
    end

    context "vApp is stopped" do
      before do
        VCloudSdk::Test::ResponseMapping
          .set_option vapp_power_state: :off
      end

      context "vApp has no running_tasks" do
        it "deletes target vApp successfully" do
          subject
            .send(:connection)
            .should_receive(:delete)
            .with(VCloudSdk::Test::Response::INSTANTIATED_VAPP_LINK)
            .and_call_original
          result = subject.delete
          result.should be_nil
        end

        it "fails to delete vApp" do
          subject
            .should_receive(:task_is_success)
            .at_least(3)
            .and_return(false)

          expect { subject.delete }
            .to raise_exception VCloudSdk::ApiTimeoutError,
                                "Task Deleting Virtual Application (#{VCloudSdk::Test::Response::VAPP_ID})" +
                                " did not complete within limit of 3 seconds."
        end
      end

      context "vApp has running_tasks" do
        it "waits until running tasks complete" do
          deletion_running_task = VCloudSdk::Xml::WrapperFactory.wrap_document(
            VCloudSdk::Test::Response::INSTANTIATED_VAPP_DELETE_RUNNING_TASK)
          running_tasks = [deletion_running_task]
          VCloudSdk::Xml::VApp
            .any_instance
            .should_receive(:running_tasks)
            .twice
            .and_return(running_tasks)

          result = subject.delete
          result.should be_nil
        end
      end
    end

    context "vApp is powered on" do
      before do
        VCloudSdk::Test::ResponseMapping
          .set_option vapp_power_state: :on
      end

      it "fails to delete target vApp" do
        expect do
          subject.delete
        end.to raise_exception VCloudSdk::CloudError,
                               "vApp #{vapp_name} is powered on, power-off before deleting."
      end
    end
  end

  describe "#power_on" do
    context "vApp is powered off" do
      before do
        VCloudSdk::Test::ResponseMapping
          .set_option vapp_power_state: :powered_off
      end

      it "powers on target vApp successfully" do
        subject
          .send(:connection)
          .should_receive(:post)
          .with(VCloudSdk::Test::Response::INSTANTIATED_VAPP_POWER_ON_LINK,
                nil)
          .and_call_original
        result = subject.power_on
        result.should be_an_instance_of(VCloudSdk::VApp)
      end

      context "request to power on vApp times out" do
        it "fails to power on vApp" do
          subject
            .should_receive(:task_is_success)
            .at_least(3)
            .and_return(false)

          expect { subject.power_on }
            .to raise_exception VCloudSdk::ApiTimeoutError,
                                "Task Starting Virtual Application test17_3_8(2b685484-ed2f-48c3-9396-5ad29cb282f4)" +
                                " did not complete within limit of 3 seconds."
        end
      end
    end

    context "vApp is powered on" do
      before do
        VCloudSdk::Test::ResponseMapping
          .set_option vapp_power_state: :on
      end

      it "does not try to power on vApp again" do
        subject.send(:connection)
          .should_not_receive(:post)

        subject.power_on
      end
    end
  end

  describe "#power_off" do

    context "vApp is powered on" do
      before do
        VCloudSdk::Test::ResponseMapping
          .set_option vapp_power_state: :on
      end

      it "powers off target vApp successfully" do
        subject
          .send(:connection)
          .should_receive(:post)
          .with(VCloudSdk::Test::Response::INSTANTIATED_VAPP_POWER_OFF_LINK,
                nil)
          .and_call_original
        subject
          .send(:connection)
          .should_receive(:post)
          .with(VCloudSdk::Test::Response::INSTANTIATED_VAPP_UNDEPLOY_LINK,
                an_instance_of(VCloudSdk::Xml::Wrapper))
        .and_call_original
        result = subject.power_off
        result.should be_an_instance_of(VCloudSdk::VApp)
      end

      context "request to power off vApp times out" do
        it "fails to power off vApp" do
          subject
            .should_receive(:task_is_success)
            .at_least(3)
            .and_return(false)

          expect { subject.power_off }
            .to raise_exception VCloudSdk::ApiTimeoutError,
                                "Task Starting Virtual Application test17_3_8(2b685484-ed2f-48c3-9396-5ad29cb282f4)" +
                                " did not complete within limit of 3 seconds."
        end
      end
    end

    context "vApp is powered off" do
      before do
        VCloudSdk::Test::ResponseMapping
          .set_option vapp_power_state: :powered_off
      end

      it "does not try to power off the vApp again" do
        subject.send(:connection)
          .should_not_receive(:post)

        subject.power_off
      end
    end

    context "vApp is suspended" do
      before do
        VCloudSdk::Test::ResponseMapping
          .set_option vapp_power_state: :suspended
      end

      it "raises an error" do
        subject.send(:connection)
          .should_not_receive(:post)

        expect { subject.power_off }
          .to raise_exception VCloudSdk::VappSuspendedError,
                              "VApp #{vapp_name} suspended, discard state before powering off."
      end
    end
  end

  describe "#recompose_from_vapp_template" do
    context "vapp is powered off" do
      before do
        VCloudSdk::Test::ResponseMapping
        .set_option vapp_power_state: :off
        VCloudSdk::Test::ResponseMapping
        .set_option catalog_state: :not_added
      end

      context "vapp template exists" do
        before do
          VCloudSdk::Test::ResponseMapping
            .set_option catalog_state: :added
        end

        context "error occurred in recomposing request" do
          it "raises the exception" do
            subject
              .send(:connection)
              .stub(:post)
              .with(VCloudSdk::Test::Response::RECOMPOSE_VAPP_LINK, anything)
              .and_raise RestClient::BadRequest

            expect do
              subject.recompose_from_vapp_template catalog_name,
                                                   VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME
            end.to raise_exception RestClient::BadRequest
          end
        end

        it "adds vm to target vapp" do
          subject
            .recompose_from_vapp_template catalog_name,
                                          VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME
        end
      end

      context "vapp template does not exist" do
        before do
          VCloudSdk::Test::ResponseMapping
            .set_option catalog_state: :not_added
        end

        it "raises ObjectNotFoundError" do
          expect do
            subject
              .recompose_from_vapp_template catalog_name,
                                            VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME
          end.to raise_exception VCloudSdk::ObjectNotFoundError
                                 "Catalog Item '#{VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME}' is not found"
        end
      end
    end

    context "vapp is powered on" do
      before do
        VCloudSdk::Test::ResponseMapping
          .set_option vapp_power_state: :on
      end

      it "raises an exception" do
        expect do
          subject
            .recompose_from_vapp_template catalog_name,
                                          VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME
        end.to raise_exception VCloudSdk::CloudError
               "VApp is in status of 'POWERED_OFF' and can not be recomposed"
      end
    end
  end

  describe "#vms" do
    before do
      VCloudSdk::Test::ResponseMapping
        .set_option vapp_power_state: :on
    end

    it "returns a collection of vms" do
      vms = subject.vms
      vms.should have_at_least(1).item
      vms.each do |vm|
        vm.should be_an_instance_of VCloudSdk::VM
      end
    end
  end

  describe "#list_vms" do
    before do
      VCloudSdk::Test::ResponseMapping
      .set_option vapp_power_state: :on
    end

    it "returns a collection of vm names" do
      vm_names = subject.list_vms
      vm_names.should eql [VCloudSdk::Test::Response::VM_NAME]
    end
  end

  describe "#find_vm_by_name" do
    before do
      VCloudSdk::Test::ResponseMapping
        .set_option vapp_power_state: :on
    end

    context "VM matching name exists" do
      it "returns the matching vm" do
        vm = subject.find_vm_by_name(VCloudSdk::Test::Response::VM_NAME)
        vm.name.should eql VCloudSdk::Test::Response::VM_NAME
      end
    end

    context "VM matching name does not exist" do
      it "raises ObjectNotFoundError" do
        expect do
          subject.find_vm_by_name("xxxx")
        end.to raise_exception VCloudSdk::ObjectNotFoundError
                               "VM 'xxxx' is not found"
      end
    end
  end

  describe "#vm_exists?" do
    before do
      VCloudSdk::Test::ResponseMapping
      .set_option vapp_power_state: :on
    end

    context "VM matching name exists" do
      it "returns true" do
        subject.vm_exists?(VCloudSdk::Test::Response::VM_NAME).should be_true
      end
    end

    context "VM matching name does not exist" do
      it "returns false" do
        subject.vm_exists?("xxx").should be_false
      end
    end
  end

  describe "#status" do
    context "vApp is powered on" do
      it "returns status POWERED_ON" do
        VCloudSdk::Test::ResponseMapping
          .set_option vapp_power_state: :on
        subject.status.should eql "POWERED_ON"
      end
    end

    context "vApp is powered off" do
      it "returns the status POWERED_OFF" do
        VCloudSdk::Test::ResponseMapping
          .set_option vapp_power_state: :powered_off
        subject.status.should eql "POWERED_OFF"
      end
    end

    context "vApp is powered off and undeployed" do
      it "returns the status POWERED_OFF" do
        VCloudSdk::Test::ResponseMapping
          .set_option vapp_power_state: :off
        subject.status.should eql "POWERED_OFF"
      end
    end

    context "vApp is suspended" do
      it "returns the status SUSPENDED" do
        VCloudSdk::Test::ResponseMapping
          .set_option vapp_power_state: :suspended
        subject.status.should eql "SUSPENDED"
      end
    end
  end

  describe "#remove_vm_by_name" do
    context "vapp is powered off" do
      before do
        VCloudSdk::Test::ResponseMapping
          .set_option vapp_power_state: :off
      end

      it "raises ObjectNotFoundError" do
        expect do
          subject.remove_vm_by_name "not-existing"
        end.to raise_exception VCloudSdk::ObjectNotFoundError
                "VM 'not-existing' is not found"
      end

      it "remove the target vm" do
        subject.remove_vm_by_name VCloudSdk::Test::Response::VM_NAME
      end
    end

    context "vapp is powered on" do
      before do
        VCloudSdk::Test::ResponseMapping
          .set_option vapp_power_state: :on
      end

      it "raises CloudError exception" do
        expect do
          subject.remove_vm_by_name VCloudSdk::Test::Response::VM_NAME
        end.to raise_exception VCloudSdk::CloudError
                "VApp is in status of 'POWERED_OFF' and can not be recomposed"
      end
    end
  end

  describe "#list_networks" do
    before do
      VCloudSdk::Test::ResponseMapping
        .set_option vapp_power_state: :off
    end

    it "returns a collection of network names" do
      network_names = subject.list_networks
      network_names.should eql([network_name])
    end
  end

  describe "#add_network_by_name" do
    before do
      VCloudSdk::Test::ResponseMapping
        .set_option vapp_power_state: :off
    end

    it "adds the network to vapp" do
      task = subject.add_network_by_name(network_name)
      subject
        .send(:task_is_success, task)
        .should be_true
    end

    context "optional parameters are specified" do
      it "adds the network to vapp" do
        task = subject
                 .add_network_by_name(network_name,
                                      "new network",
                                      VCloudSdk::Xml::FENCE_MODES[:ISOLATED])
        subject
          .send(:task_is_success, task)
          .should be_true
      end

      context "invalid fence mode is specified" do
        it "raises CloudError" do
          expect do
            subject.add_network_by_name(network_name, "new network", "dummy")
          end.to raise_exception VCloudSdk::CloudError,
                                 "Invalid fence mode 'dummy'"
        end
      end
    end

    context "network with the name does not exist" do
      it "raises ObjectNotFoundError" do
        expect do
          subject.add_network_by_name("dummy")
        end.to raise_exception VCloudSdk::ObjectNotFoundError,
                               "Network 'dummy' is not found"
      end
    end

    context "error occurred in adding network request" do
      it "raises the exception" do
        subject
          .send(:connection)
          .stub(:put)
          .with(anything,
                anything,
                VCloudSdk::Xml::MEDIA_TYPE[:NETWORK_CONFIG_SECTION])
          .and_raise RestClient::BadRequest

        expect do
          subject.add_network_by_name(network_name)
        end.to raise_exception RestClient::BadRequest
      end
    end
  end

  describe "#delete_network_by_name" do
    before do
      VCloudSdk::Test::ResponseMapping
      .set_option vapp_power_state: :off
    end

    it "deletes the network from vapp" do
      expect do
        subject.delete_network_by_name(network_name)
      end.to_not raise_error
    end

    context "network with the name does not exist" do
      it "raises ObjectNotFoundError" do
        expect do
          subject.delete_network_by_name("dummy")
        end.to raise_exception VCloudSdk::ObjectNotFoundError,
                               "Network 'dummy' is not found"
      end
    end

    context "network is being used by one or more VMs" do
      let(:vm1) { double("vm1", name: "vm1") }

      it "raises CloudError" do
        vm1.should_receive(:list_networks) { ["#{network_name}"] }
        subject.should_receive(:vms) { [vm1] }
        expect do
          subject.delete_network_by_name(network_name)
        end.to raise_exception VCloudSdk::CloudError,
                               /.+Network '#{network_name}' is being used by one or more VMs.+/
      end
    end

    context "error occurred in deleting network request" do
      it "raises the exception" do
        subject
          .send(:connection)
          .stub(:put)
          .with(anything,
                anything,
                VCloudSdk::Xml::MEDIA_TYPE[:NETWORK_CONFIG_SECTION])
          .and_raise RestClient::BadRequest

        expect do
          subject.delete_network_by_name(network_name)
        end.to raise_exception RestClient::BadRequest
      end
    end
  end
end
