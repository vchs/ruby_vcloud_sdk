require "spec_helper"
require "nokogiri/diff"
require "resolv"

describe VCloudSdk::Network do

  let(:logger) { VCloudSdk::Config.logger }
  let(:url) { ENV['VCLOUD_URL'] || VCloudSdk::Test::DefaultSetting::VCLOUD_URL }
  let(:username) { ENV['VCLOUD_USERNAME'] || VCloudSdk::Test::DefaultSetting::VCLOUD_USERNAME }
  let(:password) { ENV['VCLOUD_PWD'] || VCloudSdk::Test::DefaultSetting::VCLOUD_PWD }
  let(:vdc_name) { ENV['VDC_NAME'] || VCloudSdk::Test::DefaultSetting::VDC_NAME }

  subject do
    client = VCloudSdk::Client.new(url, username, password, {}, logger)
    vdc = client.find_vdc_by_name(vdc_name)
    vdc.networks.first
  end

  describe "#ip_ranges" do
    it "has correct ip ranges" do
      ip_ranges= subject.ip_ranges
      ip_ranges.should be_an_instance_of VCloudSdk::IpRanges

      ranges = ip_ranges.ranges
      ranges.should have_at_least(1).item
      ranges.each do |i|
        i.should be_an_instance_of String
        i.should match Resolv::IPv4::Regex
      end
    end
  end

  describe "#allocated_addresses" do
    it "has correct allocated addresses" do
      allocated_ips = subject.allocated_ips
      allocated_ips.should have_at_least(1).item
      allocated_ips.each do |ip|
        ip.should be_an_instance_of String
        ip.should match Resolv::IPv4::Regex
      end
    end
  end
end
