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

  describe "disk manipulation" do
    it "attaches and detaches the disk successfully" do
      begin
        vdc = client.find_vdc_by_name(vdc_name)
        vapp_name = SecureRandom.uuid
        catalog = client.find_catalog_by_name(catalog_name)
        vapp = catalog.instantiate_vapp_template(vapp_template_name, vdc_name, vapp_name)
        vm = vapp.vms.first
        vm.independent_disks.should eql []

        new_disk_name = "test2"
        new_disk = vdc.create_disk(new_disk_name, 1024, vm)
        new_disk.name.should eql new_disk_name
        new_disk.should_not be_attached

        vm.attach_disk(new_disk)
        new_disk.should be_attached
        new_disk.vm.href.should eql vm.href
        vm.independent_disks.size.should eql 1
        vm.detach_disk(new_disk)
        vm.independent_disks.should eql []
      ensure
        vapp.delete
        new_disk.delete
      end
    end
  end

  describe "vm manipulation" do
    it "powers on and powers off vm successfully" do
      begin
        vapp_name = SecureRandom.uuid
        catalog = client.find_catalog_by_name(catalog_name)
        vapp = catalog.instantiate_vapp_template(vapp_template_name, vdc_name, vapp_name)
        vm = vapp.vms.first
        vm.power_on
        vm.power_off
      ensure
        vapp.delete
      end
    end
  end
end
