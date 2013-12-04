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
    catalog.items[0]
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

  describe "#href" do
    it "returns the entity" do
      subject
        .href
        .end_with?(VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_ID)
        .should be_true
    end
  end

  describe "#remove_link" do
    it "returns the remove link" do
      subject
        .remove_link
        .href
        .end_with? VCloudSdk::Test::Response::EXISTING_VAPP_TEMPLATE_CATALOG_ITEM_ID
        .should be_true
    end
  end

  describe "#delete" do
    it "deletes a catalog item which has a running task", :positive do
      VCloudSdk::Test::ResponseMapping.set_option existing_media_state: :busy
      subject = catalog.items[1]
      subject.delete
    end

    it "deletes a catalog item which has no running task", :positive do
      VCloudSdk::Test::ResponseMapping.set_option existing_media_state: :done
      subject = catalog.items[1]
      subject.delete
    end

    it "raises TimeoutError when the task cannot finish within time" do
      VCloudSdk::Test::ResponseMapping.set_option existing_media_state: :busy
      subject = catalog.items[1]
      subject
        .should_receive(:task_is_success)
        .at_least(3)
        .and_return(false)

      expect { subject.delete }
        .to raise_exception VCloudSdk::ApiTimeoutError
    end
  end
end
