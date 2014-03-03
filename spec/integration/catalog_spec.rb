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
  let(:vapp_template_name) { VCloudSdk::Test::DefaultSetting::EXISTING_VAPP_TEMPLATE_NAME }
  let!(:client) { VCloudSdk::Client.new(url, username, password, {}, logger) }

  subject do
    client.find_catalog_by_name(catalog_name)
  end

  describe "#find_vapp_template_by_name" do

    it "find that targeted vapp template if it exists" do
      vapp_template = subject.find_vapp_template_by_name(vapp_template_name)
      vapp_template.name.should eq vapp_template_name
      vapp_template.should_not be_nil
    end

    it "raises exception if the targeted vapp template does not exist" do
      vapp_template_name = SecureRandom.uuid
      expect { subject.find_vapp_template_by_name(vapp_template_name) }
        .to raise_exception VCloudSdk::ObjectNotFoundError,
                            "Catalog Item '#{vapp_template_name}' is not found"
    end
  end

  describe "#instantiate_vapp_template" do
    it "starts vapp that targeted vapp template without disk locality" do
      vapp_name = SecureRandom.uuid
      vapp = subject.instantiate_vapp_template(vapp_template_name, vdc_name, vapp_name)
      vapp.should_not be_nil
      vapp.name.should eq vapp_name
    end

    it "starts vapp that targeted vapp template with disk locality" do
      new_disk_name = "independent_disk"
      vdc = client.find_vdc_by_name(vdc_name)
      new_disk = vdc.create_disk(new_disk_name, 1024)
      new_disk.name.should eql new_disk_name

      vapp_name = SecureRandom.uuid
      disk_locality = [new_disk.href]
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

    it "raises exception if the targeted catalog item does not exist" do
      catalog_item_name = SecureRandom.uuid
      expect { subject.find_item(catalog_item_name) }
        .to raise_exception VCloudSdk::ObjectNotFoundError,
                            "Catalog Item '#{catalog_item_name}' is not found"
    end

    it "raises exception if the targeted catalog item type does not match" do
      catalog_item_name = "sc-1f9f883e-968c-4bad-88e3-e7cb36881788"
      catalog_item_type = VCloudSdk::Xml::MEDIA_TYPE[:MEDIA]
      expect do
        subject.find_item(
          catalog_item_name, catalog_item_type
        )
      end.to raise_exception VCloudSdk::ObjectNotFoundError,
                             "Catalog Item '#{catalog_item_name}' is not found"
    end
  end
end
