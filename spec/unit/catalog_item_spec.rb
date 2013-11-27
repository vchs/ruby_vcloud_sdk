require "spec_helper"
require_relative "mocks/client_response"
require_relative "mocks/response_mapping"
require_relative "mocks/rest_client"
require "nokogiri/diff"

describe VCloudSdk::CatalogItem do

  let(:logger) { VCloudSdk::Test.logger }
  let(:url) { VCloudSdk::Test::Response::URL }
  let(:session) { VCloudSdk::Test.mock_session(logger, url) }

  let(:catalog) do
    org_response = VCloudSdk::Xml::WrapperFactory.wrap_document(
      VCloudSdk::Test::Response::ORG_RESPONSE)

    VCloudSdk::Catalog.new(session, org_response.catalogs.first)
  end

  before do
    VCloudSdk::Test::ResponseMapping.set_option catalog_state: :added
    VCloudSdk::Test::ResponseMapping.set_option vapp_state: :nothing
  end

  subject do
    described_class.new(session, catalog.items[0])
  end

  describe "#name" do
    it "returns the catalog item name" do
      subject.name.should eq VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME
    end
  end

  describe "#type" do
    it "returns the catalog item type" do
      subject.type.should eq VCloudSdk::Xml::MEDIA_TYPE[:VAPP_TEMPLATE]
    end
  end

  describe "#entity" do
    it "returns the entity" do
      subject.entity[:name].should eq VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME
      subject.entity[:type].should eq VCloudSdk::Xml::MEDIA_TYPE[:VAPP_TEMPLATE]
    end
  end
end
