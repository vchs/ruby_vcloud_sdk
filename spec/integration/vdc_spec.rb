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

  its(:storage_profiles) { should have_at_least(1).items }
end
