require "spec_helper"
require "nokogiri/diff"

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

  describe "#ip_range" do
    it "has correct ip range" do
      subject
        .ip_range
        .should be_an_instance_of VCloudSdk::IpRange
    end
  end

end
