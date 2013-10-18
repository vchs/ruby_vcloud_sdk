require "spec_helper"
require "nokogiri/diff"

describe VCloudSdk::Client do

  let(:logger) { VCloudSdk::Config.logger }
  let(:url) { ENV['VCLOUD_URL'] || 'https://10.146.21.135' }
  let(:username) { ENV['VCLOUD_USERNAME'] || 'dev_mgr@dev' }
  let(:password) { ENV['VCLOUD_PWD'] || 'vmware' }
  let(:vdc_name) { ENV['VDC_NAME'] }

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
