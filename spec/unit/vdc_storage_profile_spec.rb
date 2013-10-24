require "spec_helper"
require_relative "mocks/client_response"
require_relative "mocks/response_mapping"
require "nokogiri/diff"

describe VCloudSdk::VdcStorageProfile do

  subject do
    storage_profile_response = VCloudSdk::Xml::WrapperFactory.wrap_document(
      VCloudSdk::Test::Response::ORG_VDC_STORAGE_PROFILE_RESPONSE)
    described_class.new(storage_profile_response)
  end

  describe "#available_storage" do

    it "return storageLimitMB - storageUsedMB" do
      storage_limit_mb = 100
      storage_used_mb = 50
      subject.instance_variable_set(:@storage_limit_mb, storage_limit_mb)
      subject.instance_variable_set(:@storage_used_mb, storage_used_mb)
      subject.available_storage.should eql storage_limit_mb - storage_used_mb
    end

    it "return -1 if 'storageLimitMB' is 0" do
      storage_limit_mb = 0
      subject.instance_variable_set(:@storage_limit_mb, storage_limit_mb)
      subject.available_storage.should eql -1
    end
  end
end
