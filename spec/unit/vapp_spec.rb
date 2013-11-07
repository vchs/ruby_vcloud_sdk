require "spec_helper"
require_relative "mocks/client_response"
require_relative "mocks/response_mapping"
require_relative "mocks/rest_client"
require "nokogiri/diff"

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
      VCloudSdk::Test::ResponseMapping.set_option delete_vapp_task_state: :running
    end

    context "vApp is powered off" do
      it "deletes target vApp successfully" do
        deletion_task = subject.delete
        subject.send(:task_is_success, deletion_task)
          .should be_true
      end
    end

    context "vApp is powered on" do
      it "fails to deletes target vApp" do
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

    context "vApp has running_tasks" do
      it "waits until running tasks completes" do
        pending
      end
    end
  end
end
