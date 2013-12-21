require "spec_helper"
require_relative "mocks/client_response"
require_relative "mocks/response_mapping"
require_relative "mocks/rest_client"
require "ruby_vcloud_sdk/edge_gateway"
require "nokogiri/diff"

describe VCloudSdk::EdgeGateway do

  let(:logger) { VCloudSdk::Test.logger }
  let(:url) { VCloudSdk::Test::Response::URL }

  subject do
    session = VCloudSdk::Test.mock_session(logger, url)
    described_class.new(session,
                        VCloudSdk::Test::Response::ORG_VDC_EDGE_GATEWAY_LINK)
  end

  describe "#name" do
    it "returns the name of edge gateway" do
      subject.name.should eql "164-935"
    end
  end

  describe "#public_ip_ranges" do
    it "has correct ip ranges" do
      ip_ranges = subject.public_ip_ranges
      ip_ranges.should be_an_instance_of VCloudSdk::IpRanges

      ranges = ip_ranges.ranges
      ranges.should be_an_instance_of Set
      ranges.should have(4).item
      result = VCloudSdk::IpRanges
                 .new("192.240.155.231-192.240.155.234")
                 .ranges
      ranges.should eql result
    end

    context "gateway has not public IPs" do
      it "return empty ip ranges" do
        VCloudSdk::Xml::GatewayInterface
          .any_instance
          .stub(:ip_ranges)
          .and_return nil
        ip_ranges = subject.public_ip_ranges
        ip_ranges.should be_an_instance_of VCloudSdk::IpRanges
        ip_ranges.ranges.should be_empty
      end
    end
  end
end
