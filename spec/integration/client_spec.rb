require "spec_helper"
require "nokogiri/diff"

describe VCloudSdk::Client do

  let(:logger) { VCloudSdk::Config.logger }
  let(:url) { ENV['VCLOUD_URL'] || 'https://10.146.21.135' }
  let(:username) { ENV['VCLOUD_USERNAME'] || 'dev_mgr@dev' }
  let(:password) { ENV['VCLOUD_PWD'] || 'vmware' }

  # TODO: we only have the initialize funtion in client lib code now,
  # will add more as client lib code grow.
  describe "#initialize" do
    it "set up connection successfully" do
      described_class.new(url, username, password, {}, logger)
    end

    it "given incorrect url" do
      expect {
        described_class.new(url + 'wronglink', username, password, {}, logger)
      }.to raise_error(SocketError, /nodename nor servname provided,
                                      or not known/)
    end

    it "given incorrect username/pwd" do
      expect {
        described_class.new(url, username, 'wrongpassword', {}, logger)
      }.to raise_error(RestClient::Unauthorized, /401 Unauthorized/)
    end
  end
end
