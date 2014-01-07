require "spec_helper"
require_relative "mocks/client_response"
require_relative "mocks/response_mapping"
require_relative "mocks/rest_client"
require "nokogiri/diff"

describe VCloudSdk::Client, :min, :all do

  let(:logger) { VCloudSdk::Test.logger }
  let(:url) { VCloudSdk::Test::Response::URL }
  let(:username) { "cfadmin" }
  let(:password) { "akimbi" }
  let(:conn) { double("Connection") }
  let(:catalog_name) { VCloudSdk::Test::Response::CATALOG_NAME }

  let!(:mock_conn) do
    VCloudSdk::Test.mock_connection(logger, url)
  end

  let(:session) do
    VCloudSdk::Xml::WrapperFactory
      .wrap_document(VCloudSdk::Test::Response::SESSION)
  end

  let(:org_response) do
    VCloudSdk::Xml::WrapperFactory
      .wrap_document(VCloudSdk::Test::Response::ORG_RESPONSE)
  end

  describe "#initialize" do
    it "initializes with no optional params" do
      VCloudSdk::Connection::Connection
        .should_receive(:new)
        .once
        .and_return(mock_conn)
      described_class.new(url, username, password)
    end
  end

  describe "#find_vdc_by_name" do
    subject { initialize_client }

    it "fail if targeted vdc does not exist" do
      expect { subject.find_vdc_by_name("xxxx") }.to raise_error
    end

    it "find targeted vdc if it exists" do
      vdc = subject.find_vdc_by_name(VCloudSdk::Test::Response::OVDC)
      vdc.should_not be_nil
    end
  end

  describe "#catalogs" do
    subject { initialize_client }

    it "returns array of Catalog objects" do
      catalogs = subject.catalogs
      catalogs.should have(3).items
      catalogs.each do |catalog|
        catalog.should be_an_instance_of VCloudSdk::Catalog
      end
    end
  end

  describe "#list_catalogs" do
    subject { initialize_client }

    it "returns array of catalog names" do
      catalog_names = subject.list_catalogs
      catalog_names
        .should eql [VCloudSdk::Test::Response::CATALOG_NAME,
                     "Public Catalog",
                     "images"]
    end
  end

  describe "#catalog_exists?" do
    subject { initialize_client }

    context "catalog with matching name exists" do
      it "returns true" do
        subject.catalog_exists? catalog_name
      end
    end

    context "catalog with matching name does not exist" do
      it "returns false" do
        subject.catalog_exists? "xxx"
      end
    end
  end

  describe "#find_catalog_by_name" do
    subject { initialize_client }

    context "target catalog does not exist" do
      it "raises an error" do
        expect { subject.find_catalog_by_name("xxxx") }
          .to raise_exception "Catalog 'xxxx' is not found"
      end
    end

    it "returns the catalog object if target catalog exists" do
      VCloudSdk::Test::ResponseMapping.set_option catalog_state: :added
      catalog = subject.find_catalog_by_name(catalog_name)
      catalog.name.should eql VCloudSdk::Test::Response::CATALOG_NAME
    end
  end

  describe "#create_catalog" do
    subject { initialize_client }

    it "creates target catalog successfully" do
      VCloudSdk::Test::ResponseMapping.set_option catalog_created: true
      catalog = subject.create_catalog(VCloudSdk::Test::DefaultSetting::CATALOG_NAME_TO_CREATE)
      catalog.should be_an_instance_of VCloudSdk::Catalog
    end

    it "fails if targeted catalog with the same name already exists" do
      expect { subject.create_catalog(catalog_name) }.to raise_error("400 Bad Request")
    end
  end

  describe "#delete_catalog" do
    subject { initialize_client }

    context "target catalog has no items" do
      it "deletes target catalog successfully" do
        VCloudSdk::Test::ResponseMapping.set_option catalog_state: :not_added
        delete_catalog
      end
    end

    context "target catalog has existing items" do
      it "deletes target catalog successfully" do
        VCloudSdk::Test::ResponseMapping.set_option catalog_state: :added
        VCloudSdk::Test::ResponseMapping.set_option existing_media_state: :done
        delete_catalog
      end
    end

    context "targeted catalog does not exist" do
      it "raises an error" do
        catalog_name_to_create = "XXXX"
        expect { subject.delete_catalog(catalog_name_to_create) }
          .to raise_error "Catalog 'XXXX' is not found"
      end
    end

    private

    def delete_catalog
      org_response = VCloudSdk::Xml::WrapperFactory.wrap_document(
        VCloudSdk::Test::Response::ORG_RESPONSE)
      catalog = VCloudSdk::Catalog.new(VCloudSdk::Test.mock_session(logger, url),
                                       org_response.catalogs.first)
      subject.should_receive(:find_catalog_by_name)
        .with(catalog_name).once.and_return(catalog)

      response = subject.delete_catalog(catalog_name)
      response.should be_nil
    end
  end

  private

  def initialize_client
    VCloudSdk::Connection::Connection.stub(:new) { mock_conn }
    described_class.new(url, username, password, {}, logger)
  end
end
