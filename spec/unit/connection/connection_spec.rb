require "spec_helper"

describe VCloudSdk::Connection::Connection do
  let(:url) { "https://10.147.0.0:8443" }

  describe "#initialize" do
    it "use settings in input arguments" do
      site = double("site")
      file_uploader = double("File Uploader")
      conn = described_class.new(url, nil, nil, site, file_uploader)

      VCloudSdk::Test.verify_settings conn,
                                      :@site => site,
                                      :@file_uploader => file_uploader
    end
  end
end
