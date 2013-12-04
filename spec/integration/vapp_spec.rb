require "spec_helper"
require "nokogiri/diff"

describe VCloudSdk::VApp do

  let(:logger) { VCloudSdk::Test.logger }
  let(:url) { ENV['VCLOUD_URL'] || VCloudSdk::Test::DefaultSetting::VCLOUD_URL }
  let(:username) { ENV['VCLOUD_USERNAME'] || VCloudSdk::Test::DefaultSetting::VCLOUD_USERNAME }
  let(:password) { ENV['VCLOUD_PWD'] || VCloudSdk::Test::DefaultSetting::VCLOUD_PWD }
  let(:vdc_name) { ENV['VDC_NAME'] || VCloudSdk::Test::DefaultSetting::VDC_NAME }
  let(:catalog_name) { ENV['CATALOG_NAME'] || VCloudSdk::Test::DefaultSetting::CATALOG_NAME }
  let(:vapp_template_name) { VCloudSdk::Test::DefaultSetting::EXISTING_VAPP_TEMPLATE_NAME }
  let(:vapp_template_for_new_vapp) { "sc-ab7586c2-f15c-4e68-af07-d09183111573" }

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
    it "adds vm to target vapp" do
      subject.vms.should have(1).item
      subject.recompose_from_vapp_template catalog_name, vapp_template_name
      subject.vms.should have(2).items
    end
  end

  after :all do
    subject.power_off
    subject.delete
  end
end
