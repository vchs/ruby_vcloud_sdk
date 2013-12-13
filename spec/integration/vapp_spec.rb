require "spec_helper"
require "nokogiri/diff"
require "rest_client"

describe VCloudSdk::VApp do

  let(:logger) { VCloudSdk::Test.logger }
  let(:url) { ENV['VCLOUD_URL'] || VCloudSdk::Test::DefaultSetting::VCLOUD_URL }
  let(:username) { ENV['VCLOUD_USERNAME'] || VCloudSdk::Test::DefaultSetting::VCLOUD_USERNAME }
  let(:password) { ENV['VCLOUD_PWD'] || VCloudSdk::Test::DefaultSetting::VCLOUD_PWD }
  let(:vdc_name) { ENV['VDC_NAME'] || VCloudSdk::Test::DefaultSetting::VDC_NAME }
  let(:catalog_name) { ENV['CATALOG_NAME'] || VCloudSdk::Test::DefaultSetting::CATALOG_NAME }
  let(:vapp_template_name) { VCloudSdk::Test::DefaultSetting::EXISTING_VAPP_TEMPLATE_NAME }
  let(:vapp_template_for_new_vapp) { "sc-ab7586c2-f15c-4e68-af07-d09183111573" }

  after :all do
    subject.power_off
    subject.delete
  end

  subject do
    VCloudSdk::Test.new_vapp(
                      url,
                      username,
                      password,
                      logger,
                      catalog_name,
                      vapp_template_for_new_vapp,
                      vdc_name)
  end

  describe "#recompose_from_vapp_template" do
    context "vapp is powered off" do
      context "vm with the same name already exists in the vApp" do
        it "raises an error" do
          subject.power_off
          expect do
            subject.recompose_from_vapp_template catalog_name,
                                                 vapp_template_for_new_vapp
          end.to raise_exception RestClient::BadRequest
        end
      end

      it "adds vm to target vapp" do
        subject.power_off
        subject.vms.should have(1).item
        subject.recompose_from_vapp_template catalog_name, vapp_template_name
        subject.vms.should have(2).items
      end
    end

    context "vapp is powered on" do
      it "raises an exception" do
        subject.power_on
        expect do
          subject
            .recompose_from_vapp_template catalog_name,
                                          vapp_template_name
        end.to raise_exception VCloudSdk::CloudError
                               "VApp is in status of 'POWERED_OFF' and can not be recomposed"
      end
    end
  end

  describe "#remove_vm" do
    context "vapp is powered off" do
      it "removes the target vm" do
        subject.power_off
        subject.vms.should have(1).item
        subject.remove_vm vapp_template_for_new_vapp
        subject.vms.should have(0).item
      end
    end

    context "vapp is powered on" do
      it "raises an exception" do
        subject.power_on
        expect do
          subject
          .remove_vm vapp_template_for_new_vapp
        end.to raise_exception VCloudSdk::CloudError
        "VApp is in status of 'POWERED_OFF' and can not be recomposed"
      end
    end
  end
end
