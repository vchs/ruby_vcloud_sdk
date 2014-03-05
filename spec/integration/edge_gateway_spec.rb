require "spec_helper"
require "nokogiri/diff"

describe VCloudSdk::EdgeGateway do

  let(:logger) { VCloudSdk::Test.logger }
  let(:url) { ENV['VCLOUD_URL'] || raise("Missing environment variable VCLOUD_URL") }
  let(:username) { ENV['VCLOUD_USERNAME'] || raise("Missing environment variable VCLOUD_USERNAME") }
  let(:password) { ENV['VCLOUD_PWD'] || raise("Missing environment variable VCLOUD_PWD") }
  let(:vdc_name) { ENV['VDC_NAME'] || raise("Missing environment variable VDC_NAME") }

  subject do
    client = VCloudSdk::Client.new(url, username, password, {}, logger)
    client
      .find_vdc_by_name(vdc_name)
      .edge_gateways
      .first
  end

  describe "#public_ip_ranges" do
    it "has correct ip ranges" do
      ip_ranges = subject.public_ip_ranges
      ip_ranges.should be_an_instance_of VCloudSdk::IpRanges
      ranges = ip_ranges.ranges
      # No public ips if ip_ranges is empty set
      unless ranges.empty?
        ranges.each do |i|
          i.should be_an_instance_of String
          i.should match Resolv::IPv4::Regex
        end
      end
    end
  end
end
