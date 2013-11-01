require "spec_helper"
require_relative "mocks/client_response"
require_relative "mocks/response_mapping"
require_relative "mocks/rest_client"
require "nokogiri/diff"

describe VCloudSdk::Catalog do

  let(:logger) { VCloudSdk::Config.logger }
  let(:url) { VCloudSdk::Test::Response::URL }

  let(:mock_session) do
    session = double("session")
    connection = VCloudSdk::Test.mock_connection(logger, url)
    session.stub(:connection).and_return(connection)
    session
  end

  subject do
    org_response = VCloudSdk::Xml::WrapperFactory.wrap_document(
      VCloudSdk::Test::Response::ORG_RESPONSE)

    described_class.new(mock_session, org_response.catalogs.first)
  end

  before do
    VCloudSdk::Test::ResponseMapping.set_option catalog_state: :added
  end

  describe "#catalog_items" do
    its(:catalog_items) { should have_at_least(1).item }
  end

  describe "#delete_all_catalog_items" do
    it "deletes all items successfully" do
      response = subject.delete_all_catalog_items
      response[0].name.should eql VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_NAME
      response[1].name.should eql VCloudSdk::Test::Response::EXISTING_MEDIA_NAME
    end
  end
end
