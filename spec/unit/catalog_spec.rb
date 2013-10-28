require "spec_helper"
require_relative "mocks/client_response"
require_relative "mocks/response_mapping"
require "nokogiri/diff"

describe VCloudSdk::Catalog do

  subject do
    org_response = VCloudSdk::Xml::WrapperFactory.wrap_document(
      VCloudSdk::Test::Response::ORG_RESPONSE)
    described_class.new(org_response.catalogs.first)
  end

  it "initialize successfully" do
    subject.id.should =~ /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
  end

end
