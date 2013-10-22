require "spec_helper"
require "nokogiri/diff"

describe VCloudSdk::Client do

  let(:logger) { VCloudSdk::Config.logger }
  let(:url) { ENV['VCLOUD_URL'] || VCloudSdk::Test::DefaultSetting::VCLOUD_URL }
  let(:username) { ENV['VCLOUD_USERNAME'] || VCloudSdk::Test::DefaultSetting::VCLOUD_USERNAME }
  let(:password) { ENV['VCLOUD_PWD'] || VCloudSdk::Test::DefaultSetting::VCLOUD_PWD }
  let(:vdc_name) { ENV['VDC_NAME'] || VCloudSdk::Test::DefaultSetting::VDC_NAME }

  describe "#initialize" do
    it "set up connection successfully" do
      described_class.new(url, username, password, {}, logger)
    end

    it "given incorrect url" do
      expect do
        described_class.new(url + 'wronglink', username, password, {}, logger)
      end.to raise_error
    end

    it "given incorrect username/pwd" do
      expect do
        described_class.new(url, username, 'wrongpassword', {}, logger)
      end.to raise_error(RestClient::Unauthorized, /401 Unauthorized/)
    end

    describe "#find_vdc_by_name" do
      subject { described_class.new(url, username, password, {}, logger) }

      it "fail if targeted vdc does not exist" do
        expect { subject.find_vdc_by_name("xxxx") }.to raise_error
      end

      it "find targeted vdc if it exists" do
        vdc = subject.find_vdc_by_name(vdc_name)
        vdc.should_not be_nil
      end
    end
  end
end
