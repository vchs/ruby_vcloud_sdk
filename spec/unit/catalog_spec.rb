require "spec_helper"
require_relative "mocks/client_response"
require_relative "mocks/response_mapping"
require_relative "mocks/rest_client"
require "nokogiri/diff"
require "stringio"

describe VCloudSdk::Catalog do

  let(:logger) { VCloudSdk::Test.logger }
  let(:url) { VCloudSdk::Test::Response::URL }
  let!(:vmdk_string_io) { StringIO.new("vmdk") }
  let(:vdc_name) { VCloudSdk::Test::Response::OVDC }
  let(:vapp_name) { VCloudSdk::Test::Response::VAPP_TEMPLATE_NAME }
  let(:media_name) { VCloudSdk::Test::Response::MEDIA_NAME }
  let(:storage_profile_name) { VCloudSdk::Test::Response::STORAGE_PROFILE_NAME }
  let(:new_vapp) { double("new vapp") }
  let(:mock_ovf_directory) do
    directory = double("Directory")
    # Actual content of the OVF is irrelevant as long as the client gives
    # back the same one given to it
    directory.stub(:ovf_file_path) { "ovf_file" }
    directory.stub(:ovf_file) { StringIO.new("ovf_string") }
    directory.stub(:vmdk_file) { vmdk_string_io }
    directory.stub(:vmdk_file_path) do |file_name|
      file_name
    end
    directory
  end
  let(:mock_media_file) do
    media_string = VCloudSdk::Test::Response::MEDIA_CONTENT
    string_io = StringIO.new(media_string)
    string_io.stub(:path) { "bogus/bogus.iso" }
    string_io.stub(:stat) do
      o = Object.new
      o.stub(:size) { media_string.length }
      o
    end
    string_io
  end
  let(:file_uploader) do
    subject.send(:connection).instance_variable_get(:@file_uploader)
  end

  subject do
    org_response = VCloudSdk::Xml::WrapperFactory.wrap_document(
      VCloudSdk::Test::Response::ORG_RESPONSE)

    described_class.new(VCloudSdk::Test.mock_session(logger, url),
                        org_response.catalogs.first)
  end

  before do
    VCloudSdk::Test::ResponseMapping.set_option catalog_state: :added
    VCloudSdk::Test::ResponseMapping.set_option vapp_state: :nothing
  end

  describe "#admin_xml" do
    it "has correct name" do
      subject.send(:admin_xml).name.should eql VCloudSdk::Test::Response::CATALOG_NAME
    end

    it "throws exception if admin_catalog_xml is nil" do
      VCloudSdk::Connection::Connection
        .any_instance
        .stub(:get)

      VCloudSdk::Connection::Connection
        .any_instance
        .stub(:get)
        .with(VCloudSdk::Test::Response::CATALOG_LINK)
        .and_return nil
      expect { subject.send(:admin_xml) }.to raise_error(VCloudSdk::ObjectNotFoundError)
    end
  end

  describe "#items" do
    context "catalog has items" do
      it "returns a collection of vapp names" do
        VCloudSdk::Test::ResponseMapping.set_option catalog_state: :added
        items = subject.items
        items.should have(2).items
        items.each do |item|
          item.should be_an_instance_of VCloudSdk::CatalogItem
        end
      end
    end

    context "catalog has no item" do
      before do
        VCloudSdk::Test::ResponseMapping.set_option catalog_state: :not_added
      end

      its(:items) { should eql [] }
    end
  end

  describe "#list_items" do
    context "catalog has items" do
      it "returns a collection of vapp names" do
        VCloudSdk::Test::ResponseMapping.set_option catalog_state: :added
        items_names = subject.list_items
        items_names.should eql [VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME,
                                VCloudSdk::Test::Response::EXISTING_MEDIA_NAME]
      end
    end

    context "catalog has no item" do
      before do
        VCloudSdk::Test::ResponseMapping.set_option catalog_state: :not_added
      end

      its(:list_items) { should eql [] }
    end
  end

  describe "#delete_all_catalog_items" do
    it "deletes all items successfully" do
      VCloudSdk::Test::ResponseMapping.set_option existing_media_state: :done
      response = subject.delete_all_catalog_items
      response[0].name.should eql VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME
      response[1].name.should eql VCloudSdk::Test::Response::EXISTING_MEDIA_NAME
    end
  end

  describe "#upload_vapp_template" do

    context "A template with the same name already exists" do
      it "raises an error" do
        subject
        .should_receive(:item_exists?)
        .and_return(true)

        expect do
          subject.upload_vapp_template vdc_name, vapp_name, mock_ovf_directory, storage_profile_name
        end.to raise_exception("vApp template '#{vapp_name}' already exists" +
                                 " in catalog #{VCloudSdk::Test::Response::CATALOG_NAME}")
      end
    end

    context "uploading failed" do
      it "reports the exception" do
        file_uploader
          .should_receive(:upload)
          .with(
            VCloudSdk::Test::Response::VAPP_TEMPLATE_DISK_UPLOAD_1,
            vmdk_string_io,
            anything) do
          VCloudSdk::Test::ResponseMapping
            .set_option vapp_state: :disks_upload_failed
        end

        expect do
          subject.upload_vapp_template vdc_name, vapp_name, mock_ovf_directory, storage_profile_name
        end.to raise_exception("Error uploading vApp template")
      end
    end

    context "storage profile name is not provided" do
      it "uploads an OVF to the VDC" do
        file_uploader
          .should_receive(:upload)
          .with(
            VCloudSdk::Test::Response::VAPP_TEMPLATE_DISK_UPLOAD_1,
            vmdk_string_io,
            anything) do
          VCloudSdk::Test::ResponseMapping
            .set_option vapp_state: :disks_uploaded
        end

        catalog_item = subject
          .upload_vapp_template vdc_name, vapp_name, mock_ovf_directory
        catalog_item.name.should eql vapp_name
      end
    end

    it "uploads an OVF to the VDC" do
      file_uploader
        .should_receive(:upload)
        .with(
          VCloudSdk::Test::Response::VAPP_TEMPLATE_DISK_UPLOAD_1,
          vmdk_string_io,
          anything) do
        VCloudSdk::Test::ResponseMapping
          .set_option vapp_state: :disks_uploaded
      end

      catalog_item = subject
        .upload_vapp_template vdc_name, vapp_name, mock_ovf_directory, storage_profile_name
      catalog_item.name.should eql vapp_name
    end

  end

  describe "#upload_media" do

    context "An media with the same name already exists" do
      it "raises an error" do
        subject
         .should_receive(:item_exists?)
         .and_return(true)

        expect do
          subject.upload_media vdc_name,
                               media_name,
                               mock_media_file,
                               storage_profile_name
        end.to raise_exception("Catalog Item '#{media_name}' already exists" +
                               " in catalog #{VCloudSdk::Test::Response::CATALOG_NAME}")
      end
    end

    context "storage profile with given name does not exist" do
      it "raises an error" do
        expect do
          subject.upload_media vdc_name,
                               media_name,
                               mock_media_file,
                               "XXXX"
        end.to raise_exception("Storage profile 'XXXX' does not exist")
      end
    end

    context "uploading failed" do
      it "reports the exception" do
        file_uploader
          .should_receive(:upload)
          .and_raise "Uploading failed"

        expect do
          subject.upload_media vdc_name,
                               media_name,
                               mock_media_file,
                               storage_profile_name
        end.to raise_exception "Uploading failed"
      end
    end

    context "storage profile name is not provided" do
      it "uploads media file to the VDC" do
        file_uploader
          .should_receive(:upload) do |href, data, headers|
          href.should eql VCloudSdk::Test::Response::MEDIA_ISO_LINK
          data.read.should eql VCloudSdk::Test::Response::MEDIA_CONTENT
        end

        catalog_item = subject.upload_media vdc_name,
                                            media_name,
                                            mock_media_file
        catalog_item.name.should eql media_name
      end
    end

    it "uploads media file to the VDC" do
      file_uploader
        .should_receive(:upload) do |href, data, headers|
        href.should eql VCloudSdk::Test::Response::MEDIA_ISO_LINK
        data.read.should eql VCloudSdk::Test::Response::MEDIA_CONTENT
      end

      catalog_item = subject.upload_media vdc_name,
                                          media_name,
                                          mock_media_file,
                                          storage_profile_name
      catalog_item.name.should eql media_name
    end
  end

  describe "#find_vapp_template_by_name" do
    it "raises exception if the given vapp template name is nil" do
      expect { subject.find_vapp_template_by_name(nil) }.to raise_error
    end

    it "raises exception if the targeted vapp template doesn't exist" do
      expect { subject.find_vapp_template_by_name("not existing") }
        .to raise_exception VCloudSdk::ObjectNotFoundError,
                            "Catalog Item 'not existing' is not found"
    end

    it "find targeted vapp template if it exists" do
      vapp_template = subject.find_vapp_template_by_name(VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME)
      vapp_template.should_not be_nil
      vapp_template.name.should eq VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME
    end
  end

  describe "#instantiate_vapp_template" do
    it "instantiates a vApp from the vapp template without disk locality" do
      VCloudSdk::Test::ResponseMapping.set_option template_instantiate_state: :running
      VCloudSdk::Test::ResponseMapping.set_option vapp_power_state: :off
      VCloudSdk::VDC.any_instance
        .stub(:find_vapp_by_name)
        .with(vapp_name)
        .and_return new_vapp

      vapp = subject.instantiate_vapp_template(
          VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME,
          VCloudSdk::Test::Response::OVDC,
          vapp_name,
      )

      vapp.should eq new_vapp
    end

    it "instantiates a vApp from the vapp template with disk locality" do
      VCloudSdk::Test::ResponseMapping.set_option template_instantiate_state: :running
      VCloudSdk::Test::ResponseMapping.set_option vapp_power_state: :off
      VCloudSdk::VDC.any_instance
        .stub(:find_vapp_by_name)
        .with(vapp_name)
        .and_return new_vapp

      vapp = subject.instantiate_vapp_template(
          VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME,
          VCloudSdk::Test::Response::OVDC,
          vapp_name,
          "desc",
          [VCloudSdk::Test::Response::INDY_DISK_URL]
      )

      vapp.should eq new_vapp
    end

    it "raises an exception when vapp template cannot be found" do
      VCloudSdk::Test::ResponseMapping.set_option template_instantiate_state: :running
      VCloudSdk::Test::ResponseMapping.set_option vapp_power_state: :off

      expect do
        subject.instantiate_vapp_template(
          "not_existing_vapp_template",
          VCloudSdk::Test::Response::OVDC,
          vapp_name,
        )
      end.to raise_error VCloudSdk::ObjectNotFoundError
    end

    it "raises an exception when VDC cannot be found" do
      VCloudSdk::Test::ResponseMapping.set_option template_instantiate_state: :running
      VCloudSdk::Test::ResponseMapping.set_option vapp_power_state: :off

      expect do
        subject.instantiate_vapp_template(
            VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME,
            "not_existing_vdc",
            vapp_name,
        )
      end.to raise_error VCloudSdk::ObjectNotFoundError
    end
  end

  describe "#find_item" do
    it "raises exception if the given catalog item name is nil" do
      expect { subject.find_item(nil) }.to raise_error
    end

    it "raises exception if the targeted catalog item doesn't exist" do
      expect { subject.find_item("not existing") }
        .to raise_exception VCloudSdk::ObjectNotFoundError,
                            "Catalog Item 'not existing' is not found"
    end

    it "finds the targeted catalog item via name if it exists" do
      catalog_item = subject.find_item(VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME)
      catalog_item.should_not be_nil
      catalog_item.name.should eq VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME
    end

    it "finds the targeted catalog item via name and type if it exists" do
      catalog_item = subject.find_item(
          VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME,
          VCloudSdk::Xml::MEDIA_TYPE[:VAPP_TEMPLATE]
      )
      catalog_item.should_not be_nil
      catalog_item.name.should eq VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME
    end

    it "returns nil when the targeted catalog item type does not match" do
      expect do
        subject.find_item(
          VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME,
          VCloudSdk::Xml::MEDIA_TYPE[:MEDIA]
        )
      end.to raise_exception VCloudSdk::ObjectNotFoundError,
                             "Catalog Item '#{VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME}' is not found"
    end
  end

  describe "item_exists?" do
    it "returns false if the targeted catalog item doesn't exist" do
      subject
        .item_exists?("not existing")
        .should be_false
    end

    it "returns true if the targeted catalog item via name exists" do
      subject
        .item_exists?(VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME)
        .should be_true
    end

    it "returns true if the targeted catalog item via name and type exists" do
      subject
        .item_exists?(
          VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME,
          VCloudSdk::Xml::MEDIA_TYPE[:VAPP_TEMPLATE]
        )
        .should be_true
    end

    it "returns false when the targeted catalog item type does not match" do
        subject
          .item_exists?(
            VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME,
            VCloudSdk::Xml::MEDIA_TYPE[:MEDIA]
          )
          .should be_false
    end
  end
end
