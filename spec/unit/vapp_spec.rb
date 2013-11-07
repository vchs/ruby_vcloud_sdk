require "spec_helper"
require_relative "mocks/client_response"
require_relative "mocks/response_mapping"
require_relative "mocks/rest_client"
require "nokogiri/diff"
require "ruby_vcloud_sdk/xml/wrapper_classes/vapp"

describe VCloudSdk::VApp do

  let(:logger) { VCloudSdk::Config.logger }
  let(:url) { VCloudSdk::Test::Response::URL }
  let(:vapp_name) { VCloudSdk::Test::Response::VAPP_NAME }

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

    context "vApp is powered off" do
      context "vApp has no running_tasks" do
        it "deletes target vApp successfully" do
          deletion_task = subject.delete
          subject.send(:task_is_success, deletion_task)
            .should be_true
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

          deletion_task = subject.delete
          subject.send(:task_is_success, deletion_task)
            .should be_true
        end
      end
    end

    context "vApp is powered on" do
      it "fails to delete target vApp" do
        subject
          .should_receive(:is_vapp_status?)
          .with(anything, :POWERED_ON)
          .once
          .and_return(true)

        expect do
          subject.delete
        end.to raise_exception VCloudSdk::CloudError,
                               "vApp #{vapp_name} is powered on, power-off before deleting."
      end
    end
  end
end
