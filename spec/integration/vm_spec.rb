require "spec_helper"
require "nokogiri/diff"

describe VCloudSdk::VM do

  let(:logger) { VCloudSdk::Test.logger }
  let(:url) { ENV['VCLOUD_URL'] || VCloudSdk::Test::DefaultSetting::VCLOUD_URL }
  let(:username) { ENV['VCLOUD_USERNAME'] || VCloudSdk::Test::DefaultSetting::VCLOUD_USERNAME }
  let(:password) { ENV['VCLOUD_PWD'] || VCloudSdk::Test::DefaultSetting::VCLOUD_PWD }
  let!(:client) { VCloudSdk::Client.new(url, username, password, {}, logger) }
  let(:vdc_name) { ENV['VDC_NAME'] || VCloudSdk::Test::DefaultSetting::VDC_NAME }
  let(:vapp_name) { ENV['VAPP_NAME'] ||  VCloudSdk::Test::DefaultSetting::VAPP_NAME }
  let(:catalog_name) { ENV['CATALOG_NAME'] || VCloudSdk::Test::DefaultSetting::CATALOG_NAME }
  let(:vapp_template_name) { VCloudSdk::Test::DefaultSetting::EXISTING_VAPP_TEMPLATE_NAME }

  describe "#attach_disk" do
    it "attaches the disk successfully" do
      begin
        vapp_name = SecureRandom.uuid
        catalog = client.find_catalog_by_name(catalog_name)
        vapp = catalog.instantiate_vapp_template(vapp_template_name, vdc_name, vapp_name)
        vm = vapp.vms.first
        vm.independent_disks.should eql []

        new_disk_name = "test"
        new_disk = subject.create_disk(new_disk_name, 1024, vm)
        new_disk.name.should eql new_disk_name

        vm.attach_disk(new_disk)
        vm.independent_disks.size.should eql 1
      ensure
        vapp.delete
        new_disk.delete
      end
    end
  end

end