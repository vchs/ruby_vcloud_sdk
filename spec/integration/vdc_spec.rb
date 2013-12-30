require "spec_helper"
require "nokogiri/diff"
require "securerandom"

describe VCloudSdk::VDC do

  let(:logger) { VCloudSdk::Test.logger }
  let(:url) { ENV['VCLOUD_URL'] || VCloudSdk::Test::DefaultSetting::VCLOUD_URL }
  let(:username) { ENV['VCLOUD_USERNAME'] || VCloudSdk::Test::DefaultSetting::VCLOUD_USERNAME }
  let(:password) { ENV['VCLOUD_PWD'] || VCloudSdk::Test::DefaultSetting::VCLOUD_PWD }
  let!(:client) { VCloudSdk::Client.new(url, username, password, {}, logger) }
  let(:vdc_name) { ENV['VDC_NAME'] || VCloudSdk::Test::DefaultSetting::VDC_NAME }
  let(:storage_profile_name) { ENV['STORAGE_PROFILE_NAME'] ||  VCloudSdk::Test::DefaultSetting::STORAGE_PROFILE_NAME }
  let(:vapp_name) { ENV['VAPP_NAME'] ||  VCloudSdk::Test::DefaultSetting::VAPP_NAME }
  let(:network_name) { ENV['NETWORK_NAME'] ||  VCloudSdk::Test::DefaultSetting::NETWORK_NAME }
  let(:catalog_name) { ENV['CATALOG_NAME'] || VCloudSdk::Test::DefaultSetting::CATALOG_NAME }
  let(:vapp_template_name) { VCloudSdk::Test::DefaultSetting::EXISTING_VAPP_TEMPLATE_NAME }

  subject do
    client.find_vdc_by_name(vdc_name)
  end

  describe "#storage_profiles" do
    its(:storage_profiles) { should have_at_least(1).item }
  end

  describe "#find_storage_profile_by_name" do
    context "storage profile with given name exists" do
      it "return a storage profile given targeted name" do
        storage_profile = subject
                            .find_storage_profile_by_name(storage_profile_name)
        storage_profile.name.should eql storage_profile_name
      end
    end

    context "storage profile with given name does not exist" do
      it "raises ObjectNotFoundError" do
        expect do
          subject.find_storage_profile_by_name("xxx")
        end.to raise_exception VCloudSdk::ObjectNotFoundError,
                               "Storage profile 'xxx' is not found"
      end
    end
  end

  describe "#vapps" do
    its(:vapps) { should have_at_least(1).item }
  end

  describe "#find_vapp_by_name" do
    context "vapp with given name exists" do
      it "returns a vapp given targeted name" do
        vapp = subject.find_vapp_by_name(vapp_name)
        vapp.name.should eql vapp_name
      end
    end

    context "vapp with given name does not exist" do
      it "raises ObjectNotFoundError" do
        expect do
          subject.find_vapp_by_name("xxxx")
        end.to raise_exception VCloudSdk::ObjectNotFoundError,
                               "VApp 'xxxx' is not found"
      end
    end
  end

  describe "#resources" do
    it "returns the Resources object having the cpu instance with a valid number" do
      cpu = subject.resources.cpu
      cpu.available_cores.should_not be_nil
    end

    it "returns the Resources object having the memory instance with a valid number" do
      memory = subject.resources.memory
      memory.available_mb.should_not be_nil
    end
  end

  describe "#networks" do
    its(:networks) { should have_at_least(1).item }
  end

  describe "#find_network_by_name" do
    context "network with given name exists" do
      it "returns a network given targeted name" do
        network = subject
                    .find_network_by_name(network_name)
        network.name.should eql network_name
      end
    end

    context "network with given name does not exist" do
      it "raises ObjectNotFoundError" do
        expect do
          subject
            .find_network_by_name("xxx")
        end.to raise_exception VCloudSdk::ObjectNotFoundError,
                               "Network 'xxx' is not found"
      end
    end
  end

  describe "#disks" do
    its(:disks) { should have_at_least(1).item }
  end

  describe "#create_disk" do
    it "creates an independent disk successfully" do
      begin
        vapp_name = SecureRandom.uuid
        catalog = client.find_catalog_by_name(catalog_name)
        vapp = catalog.instantiate_vapp_template(vapp_template_name, vdc_name, vapp_name)
        vm = vapp.vms.first

        new_disk_name = "test"
        new_disk = subject.create_disk(new_disk_name, 1024, vm)
        new_disk.name.should eql new_disk_name
      ensure
        vapp.delete
        new_disk.delete
      end
    end
  end

  describe "#edge_gateways" do
    it "returns a collection of edge gateways" do
      edge_gateways = subject.edge_gateways
      edge_gateways.should have(1).item
      edge_gateway = edge_gateways.first
      edge_gateway.should be_an_instance_of VCloudSdk::EdgeGateway
    end
  end
end
