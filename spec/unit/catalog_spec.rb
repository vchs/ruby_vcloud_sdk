require "spec_helper"
require_relative "mocks/client_response"
require_relative "mocks/response_mapping"
require_relative "mocks/rest_client"
require "nokogiri/diff"
require "stringio"

describe VCloudSdk::Catalog do

  let(:logger) { VCloudSdk::Config.logger }
  let(:url) { VCloudSdk::Test::Response::URL }
  let!(:vmdk_string_io) { StringIO.new("vmdk") }
  let(:vdc_name) { VCloudSdk::Test::Response::OVDC }
  let(:vapp_name) { VCloudSdk::Test::Response::VAPP_TEMPLATE_NAME }
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
    its(:items) { should have_at_least(1).item }
  end

  describe "#delete_all_catalog_items" do
    it "deletes all items successfully" do
      response = subject.delete_all_catalog_items
      response[0].name.should eql VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME
      response[1].name.should eql VCloudSdk::Test::Response::EXISTING_MEDIA_NAME
    end
  end

  describe "#upload_vapp_template" do

    context "OVF directory is not provided" do
      it "raises error" do
        expect do
          subject
            .upload_vapp_template vdc_name, vapp_name, nil
        end.to raise_error "OVF directory is nil"
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
        .upload_vapp_template vdc_name, vapp_name, mock_ovf_directory
      catalog_item.name.should eql vapp_name
    end

    it "reports an exception upon error" do
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
        subject.upload_vapp_template vdc_name, vapp_name, mock_ovf_directory
      end.to raise_exception("Error uploading vApp template")
    end

    context "A template with the same name already exists" do
      it "raises error" do
         subject
          .should_receive(:item_exists?)
          .and_return(true)

         expect do
           subject.upload_vapp_template vdc_name, vapp_name, mock_ovf_directory
         end.to raise_exception("vApp template '#{vapp_name}' already exists" +
                                " in catalog #{VCloudSdk::Test::Response::CATALOG_NAME}")
      end
    end
  end
end
