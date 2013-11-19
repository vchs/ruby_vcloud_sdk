require "spec_helper"
require "nokogiri/diff"
require 'securerandom'

describe VCloudSdk::Catalog do

  let(:logger) { VCloudSdk::Test.logger }
  let(:url) { ENV['VCLOUD_URL'] || VCloudSdk::Test::DefaultSetting::VCLOUD_URL }
  let(:username) { ENV['VCLOUD_USERNAME'] || VCloudSdk::Test::DefaultSetting::VCLOUD_USERNAME }
  let(:password) { ENV['VCLOUD_PWD'] || VCloudSdk::Test::DefaultSetting::VCLOUD_PWD }
  let(:vdc_name) { ENV['VDC_NAME'] || VCloudSdk::Test::DefaultSetting::VDC_NAME }
  let(:catalog_name) { ENV['CATALOG_NAME'] || VCloudSdk::Test::DefaultSetting::CATALOG_NAME }

  subject do
    client = VCloudSdk::Client.new(url, username, password, {}, logger)
    client.find_catalog_by_name(catalog_name)
  end

  describe "#find_vapp_template_by_name" do

    it "find that targeted vapp template if it exists" do
      # TODO: This template already exists in WDC intergation test enviroment.
      #       We should have a story to add all the intergation test setup code like this.
      vapp_template_name = "sc-1f9f883e-968c-4bad-88e3-e7cb36881788"

      vapp_template = subject.find_vapp_template_by_name(vapp_template_name)
      vapp_template.name.should eq vapp_template_name
      vapp_template.should_not be_nil
    end

    it "return nil if the targeted vapp template does not exist" do
      vapp_template_name = SecureRandom.uuid
      vapp_template = subject.find_vapp_template_by_name(vapp_template_name)
      vapp_template.should be_nil
    end
  end
end
