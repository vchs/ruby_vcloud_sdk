require "spec_helper"
require "nokogiri/diff"
require "rest_client"

describe VCloudSdk::VApp do

  let(:logger) { VCloudSdk::Test.logger }
  let(:url) { ENV['VCLOUD_URL'] || raise("Missing environment variable VCLOUD_URL") }
  let(:username) { ENV['VCLOUD_USERNAME'] || raise("Missing environment variable VCLOUD_USERNAME") }
  let(:password) { ENV['VCLOUD_PWD'] || raise("Missing environment variable VCLOUD_PWD") }
  let(:vdc_name) { ENV['VDC_NAME'] || raise("Missing environment variable VDC_NAME") }
  let(:catalog_name) { ENV['CATALOG_NAME'] || raise("Missing environment variable CATALOG_NAME") }
  let(:vapp_template_name) do
    ENV['EXISTING_VAPP_TEMPLATE_NAME'] || raise("Missing environment variable EXISTING_VAPP_TEMPLATE_NAME")
  end
  let(:vapp_template_for_new_vapp) do
    ENV['SECOND_EXISTING_VAPP_TEMPLATE_NAME'] || raise("Missing environment variable SECOND_EXISTING_VAPP_TEMPLATE_NAME")
  end

  after :all do
    subject.power_off
    subject.delete
  end

  subject do
    VCloudSdk::Test.new_vapp(
                      url,
                      username,
                      password,
                      logger,
                      catalog_name,
                      vapp_template_for_new_vapp,
                      vdc_name)
  end

  describe "#recompose_from_vapp_template" do
    context "vapp is powered off" do
      context "vm with the same name already exists in the vApp" do
        it "raises an error" do
          subject.power_off
          expect do
            subject.recompose_from_vapp_template catalog_name,
                                                 vapp_template_for_new_vapp
          end.to raise_exception RestClient::BadRequest
        end
      end

      it "adds vm to target vapp" do
        subject.power_off
        subject.vms.should have(1).item
        subject.recompose_from_vapp_template catalog_name, vapp_template_name
        subject.vms.should have(2).items
      end
    end

    context "vapp is powered on" do
      it "raises an exception" do
        subject.power_on
        expect do
          subject
            .recompose_from_vapp_template catalog_name,
                                          vapp_template_name
        end.to raise_exception VCloudSdk::CloudError
                               "VApp is in status of 'POWERED_OFF' and can not be recomposed"
      end
    end
  end

  describe "#remove_vm_by_name" do
    context "vapp is powered off" do
      it "removes the target vm" do
        subject.power_off
        size = subject.vms.size
        subject.remove_vm_by_name subject.vms.first.name
        subject.vms.should have(size - 1).items
      end
    end

    context "vapp is powered on" do
      it "raises an exception" do
        subject.power_on
        expect do
          subject
            .remove_vm_by_name subject.vms.first.name
        end.to raise_exception VCloudSdk::CloudError,
                               "VApp is in status of 'POWERED_ON' and can not be recomposed"
      end
    end
  end

  describe "network manipulation" do
    it "adds the network to vapp and deletes it from vapp" do
      client = VCloudSdk::Client.new(url, username, password, {}, logger)
      vdc = client.find_vdc_by_name(vdc_name)
      network = vdc.networks.first
      network_name = network.name
      subject.list_networks.should eql []
      subject.add_network_by_name(network_name)
      subject.list_networks.should eql [network_name]
      subject.delete_network_by_name(network_name)
      subject.list_networks.should eql []
    end
  end
end
