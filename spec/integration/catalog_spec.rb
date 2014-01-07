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
  let(:storage_profile_name) { ENV['STORAGE_PROFILE_NAME'] ||  VCloudSdk::Test::DefaultSetting::STORAGE_PROFILE_NAME }
  let(:vapp_template_dir) { ENV['VAPP_TEMPLATE_DIR'] || "Fake path of vapp template directory" }
  let(:media_file) { ENV['MEDIA_FILE'] || "Fake path of media file" }

  let(:client) do
    VCloudSdk::Client.new(url, username, password, {}, logger)
  end
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

    xit "starts vapp that targeted vapp template with disk locality" do
      vapp_name = SecureRandom.uuid
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

  describe "#delete" do
    context "catalog has no items" do
      it "deletes catalog successfully" do
        catalog_name_to_create = SecureRandom.uuid
        catalog = client.create_catalog(catalog_name_to_create)
        catalog.name.should eql catalog_name_to_create

        result = catalog.delete
        result.should be_nil
        expect do
          client.find_catalog_by_name(catalog_name_to_create)
        end.to raise_exception VCloudSdk::ObjectNotFoundError,
                               "Catalog '#{catalog_name_to_create}' is not found"
      end
    end

    context "catalog has existing items" do
      it "deletes target catalog successfully" do
        catalog_name_to_create = SecureRandom.uuid
        catalog = client.create_catalog(catalog_name_to_create)
        catalog.name.should eql catalog_name_to_create

        begin
          vapp_name = "new vapp"
          catalog_item = catalog.upload_vapp_template vdc_name, vapp_name, vapp_template_dir
          catalog_item.name.should eql vapp_name

          media_name = "new media"
          catalog_item = catalog.upload_media vdc_name, media_name, media_file, storage_profile_name
          catalog_item.name.should eql media_name
        ensure
          catalog.delete
        end

        expect do
          client.find_catalog_by_name(catalog_name_to_create)
        end.to raise_exception VCloudSdk::ObjectNotFoundError,
                               "Catalog '#{catalog_name_to_create}' is not found"
      end
    end
  end
end
