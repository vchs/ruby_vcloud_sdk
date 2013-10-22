require "spec_helper"
require "nokogiri/diff"

describe VCloudSdk::VDC do

  let(:logger) { VCloudSdk::Config.logger }
  let(:url) { ENV['VCLOUD_URL'] || VCloudSdk::Test::DefaultSetting::VCLOUD_URL }
  let(:username) { ENV['VCLOUD_USERNAME'] || VCloudSdk::Test::DefaultSetting::VCLOUD_USERNAME }
  let(:password) { ENV['VCLOUD_PWD'] || VCloudSdk::Test::DefaultSetting::VCLOUD_PWD }
  let(:vdc_name) { ENV['VDC_NAME'] || VCloudSdk::Test::DefaultSetting::VDC_NAME }

  subject do
    client = VCloudSdk::Client.new(url, username, password, {}, logger)
    client.find_vdc_by_name(vdc_name)
  end

  its(:storage_profiles) { should have_at_least(1).items }
end
