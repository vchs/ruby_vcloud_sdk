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

  describe "#ip_ranges" do
    it "has correct ip ranges" do
      ip_ranges= subject.ip_ranges
      ip_ranges.should be_an_instance_of VCloudSdk::IpRanges

      ranges = ip_ranges.ranges
      ranges.should be_an_instance_of Array
      ranges.should have_at_least(1).item
      ranges.each do |i|
        i.should be_an_instance_of Range
        ip_range_start = i.first
        ip_range_end = i.last
        (ip_range_start.is_a?(NetAddr::CIDRv4) || ip_range_start.is_a?(NetAddr::CIDRv6))
          .should be_true
        (ip_range_end.is_a?(NetAddr::CIDRv4) || ip_range_end.is_a?(NetAddr::CIDRv6))
          .should be_true
        (ip_range_start > ip_range_end).should be_false
      end
    end
  end

  describe "#allocated_addresses" do
    it "has correct allocated addresses" do
      allocated_ips = subject.allocated_ips

      ips = ["10.146.21.151",
             "10.146.21.152",
             "10.146.21.153",
             "10.146.21.154",
             "10.146.21.155",
             "10.146.21.157",
             "10.146.21.158",
             "10.146.21.159",
             "10.146.21.160",
             "10.146.21.171",
             "10.146.21.174",
             "10.146.21.177",
             "10.146.21.220",
             "10.146.21.232"]
      allocated_ips.should eql ips
    end
  end
end