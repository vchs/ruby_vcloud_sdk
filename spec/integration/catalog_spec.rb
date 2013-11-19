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

  describe "#instantiate_vapp_template" do
    it "starts vapp that targeted vapp template without disk locality" do
      vapp_template_name = "sc-1f9f883e-968c-4bad-88e3-e7cb36881788"
      vapp_name = SecureRandom.uuid
      vapp = subject.instantiate_vapp_template(vapp_template_name, vdc_name, vapp_name)
      vapp.should_not be_nil
      vapp.name.should eq vapp_name
    end

    xit "starts vapp that targeted vapp template with disk locality" do
      vapp_template_name = "sc-1f9f883e-968c-4bad-88e3-e7cb36881788"
      vapp_name = SecureRandom.uuid
      #TODO: instantiate_vapp_template with disk locality intergration test will be added after
      #      Create Disk story is finished.
      disk_locality = nil
      vapp = subject.instantiate_vapp_template(vapp_template_name, vdc_name,
                                               vapp_name, "with_disk_locality", disk_locality)
      vapp.should_not be_nil
      vapp.name.should eq vapp_name
    end
  end

  describe "#find_item" do
    it "find that targeted catalog item via name and type if it exists" do
      catalog_item_name = "sc-1f9f883e-968c-4bad-88e3-e7cb36881788"
      catalog_item_type = VCloudSdk::Xml::MEDIA_TYPE[:VAPP_TEMPLATE]
      catalog_item = subject.find_item(
          catalog_item_name, catalog_item_type
      )
      catalog_item.name.should eq catalog_item_name
      catalog_item.should_not be_nil
    end

    it "find that targeted catalog item via name if it exists" do
      catalog_item_name = "sc-1f9f883e-968c-4bad-88e3-e7cb36881788"
      catalog_item = subject.find_item catalog_item_name
      catalog_item.name.should eq catalog_item_name
      catalog_item.should_not be_nil
    end

    it "return nil if the targeted catalog item does not exist" do
      catalog_item_name = SecureRandom.uuid
      catalog_item = subject.find_item(catalog_item_name)
      catalog_item.should be_nil
    end

    it "return nil if the targeted catalog item type does not match" do
      catalog_item_name = "sc-1f9f883e-968c-4bad-88e3-e7cb36881788"
      catalog_item_type = VCloudSdk::Xml::MEDIA_TYPE[:MEDIA]
      catalog_item = subject.find_item(
          catalog_item_name, catalog_item_type
      )
      catalog_item.should be_nil
    end
  end
end
