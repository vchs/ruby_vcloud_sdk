require "spec_helper"
require "nokogiri/diff"
require 'securerandom'

describe VCloudSdk::Client do

  let(:logger) { VCloudSdk::Test.logger }
  let(:url) { ENV['VCLOUD_URL'] || VCloudSdk::Test::DefaultSetting::VCLOUD_URL }
  let(:username) { ENV['VCLOUD_USERNAME'] || VCloudSdk::Test::DefaultSetting::VCLOUD_USERNAME }
  let(:password) { ENV['VCLOUD_PWD'] || VCloudSdk::Test::DefaultSetting::VCLOUD_PWD }
  let(:vdc_name) { ENV['VDC_NAME'] || VCloudSdk::Test::DefaultSetting::VDC_NAME }
  let(:catalog_name) { ENV['CATALOG_NAME'] || VCloudSdk::Test::DefaultSetting::CATALOG_NAME }
  let(:vapp_template_dir) { ENV['VAPP_TEMPLATE_DIR'] }

  describe "#initialize" do
    it "set up connection successfully" do
      described_class.new(url, username, password, {}, logger)
    end

    it "given incorrect url" do
      expect do
        described_class.new(url + 'wronglink', username, password, {}, logger)
      end.to raise_error
    end

    it "given incorrect username/pwd" do
      expect do
        described_class.new(url, username, 'wrongpassword', {}, logger)
      end.to raise_error(RestClient::Unauthorized, /401 Unauthorized/)
    end
  end

  describe "#find_vdc_by_name" do
    subject { described_class.new(url, username, password, {}, logger) }

    it "fail if targeted vdc does not exist" do
      expect { subject.find_vdc_by_name("xxxx") }.to raise_error
    end

    it "find targeted vdc if it exists" do
      vdc = subject.find_vdc_by_name(vdc_name)
      vdc.should_not be_nil
    end
  end

  describe "#find_catalog_by_name" do
    subject { described_class.new(url, username, password, {}, logger) }

    it "return nil if targeted catalog does not exist" do
      catalog = subject.find_catalog_by_name("xxxx")
      catalog.should be_nil
    end

    it "find targeted catalog if it exists" do
      catalog = subject.find_catalog_by_name(catalog_name)
      catalog.should_not be_nil
    end
  end

  describe "#create_catalog" do
    subject { described_class.new(url, username, password, {}, logger) }

    it "creates target catalog successfully" do
      catalog_name_to_create = SecureRandom.uuid
      catalog = subject.create_catalog(catalog_name_to_create)
      catalog.should be_an_instance_of VCloudSdk::Catalog
      catalog.name.should eql catalog_name_to_create
      result = subject.delete_catalog(catalog_name_to_create)
      result.should be_nil
    end

    it "fails if targeted catalog with the same name already exists" do
      catalog_name_to_create = SecureRandom.uuid
      subject.create_catalog(catalog_name_to_create)
      expect { subject.create_catalog(catalog_name_to_create) }.to raise_error("400 Bad Request")
      subject.delete_catalog(catalog_name_to_create)
    end

    describe "#delete_catalog" do
      subject { described_class.new(url, username, password, {}, logger) }

      context "target catalog has no items" do
        it "deletes target catalog successfully" do
          catalog_name_to_create = SecureRandom.uuid
          subject.create_catalog(catalog_name_to_create)
          catalog = subject.find_catalog_by_name(catalog_name_to_create)
          catalog.name.should eql catalog_name_to_create

          result = subject.delete_catalog(catalog_name_to_create)
          result.should be_nil
          catalog = subject.find_catalog_by_name(catalog_name_to_create)
          catalog.should be_nil
        end
      end

      context "target catalog has existing items" do
        it "deletes target catalog successfully" do
          catalog_name_to_create = SecureRandom.uuid
          subject.create_catalog(catalog_name_to_create)
          catalog = subject.find_catalog_by_name(catalog_name_to_create)
          catalog.name.should eql catalog_name_to_create

          vapp_name = "new vapp"
          catalog_item = catalog.upload_vapp_template vdc_name, vapp_name, vapp_template_dir
          catalog_item.name.should eql vapp_name
          subject.delete_catalog(catalog_name_to_create)
          catalog = subject.find_catalog_by_name(catalog_name_to_create)
          catalog.should be_nil
        end
      end

      it "fails if targeted catalog does not exist" do
        catalog_name_to_create = SecureRandom.uuid
        expect { subject.delete_catalog(catalog_name_to_create) }.to raise_error(VCloudSdk::ObjectNotFoundError, /Catalog \S+ not found/)
      end
    end

  end
end
