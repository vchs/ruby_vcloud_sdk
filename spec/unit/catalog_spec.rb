require "spec_helper"
require_relative "mocks/client_response"
require_relative "mocks/response_mapping"
require_relative "mocks/rest_client"
require "nokogiri/diff"

describe VCloudSdk::Catalog do

  let(:logger) { VCloudSdk::Config.logger }
  let(:url) { VCloudSdk::Test::Response::URL }

  let(:mock_connection) do
    VCloudSdk::Test.mock_connection(logger, url)
  end

  subject do
    org_response = VCloudSdk::Xml::WrapperFactory.wrap_document(
      VCloudSdk::Test::Response::ORG_RESPONSE)
    described_class.new(mock_connection, org_response.catalogs.first)
  end

  before do
    VCloudSdk::Catalog.any_instance.stub(:id).and_return(VCloudSdk::Test::Response::CATALOG_ID)
  end

  describe "#catalog_items" do
    its(:catalog_items) { should have_at_least(1).item }
  end

  describe "#delete_all_catalog_items" do
    it "deletes all items successfully" do
      subject.delete_all_catalog_items
    end
  end
end
