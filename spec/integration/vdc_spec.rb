require "spec_helper"
require "nokogiri/diff"

describe VCloudSdk::VDC do

  let(:logger) { VCloudSdk::Config.logger }
  let(:url) { ENV['VCLOUD_URL'] || 'https://10.146.21.135' }
  let(:username) { ENV['VCLOUD_USERNAME'] || 'dev_mgr@dev' }
  let(:password) { ENV['VCLOUD_PWD'] || 'vmware' }
  let(:vdc_name) { ENV['VDC_NAME'] }

  subject do
    client = VCloudSdk::Client.new(url, username, password, {}, logger)
    client.find_vdc_by_name(vdc_name)
  end

  describe "#storage_profiles" do
    it "give available storage profiles" do
      storage_profiles = subject.storage_profiles
      storage_profiles.length.should >= 1
    end
  end
end
