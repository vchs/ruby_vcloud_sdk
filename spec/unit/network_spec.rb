require "spec_helper"
require_relative "mocks/client_response"
require_relative "mocks/response_mapping"
require_relative "mocks/rest_client"
require "nokogiri/diff"

describe VCloudSdk::Network do

  let(:logger) { VCloudSdk::Config.logger }
  let(:url) { VCloudSdk::Test::Response::URL }
  let(:network_name) { VCloudSdk::Test::Response::ORG_NETWORK_NAME }

  subject do
    session = VCloudSdk::Test.mock_session(logger, url)
    described_class.new(session,
                        session.org.network(network_name))
  end

  describe "#ip_range" do
    it "has correct ip range" do
      subject
        .ip_range
        .should be_an_instance_of VCloudSdk::IpRange
    end
  end

  describe "#allocated_addresses" do
    it "has correct allocated addresses" do
      allocated_ips = subject.allocated_ips
      allocated_ips.should have_at_least(1).item
      allocated_ips.each do |ip|
        ip.should be_an_instance_of String
      end
    end
  end
end