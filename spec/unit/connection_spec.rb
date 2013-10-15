require "spec_helper"

module VCloudSdk
  module Test
    describe Connection, :min, :all do
      let(:url) { "https://10.147.0.0:8443" }

      describe ".initialize" do
        it "use settings in input arguments" do
          site = double("site")
          file_uploader = double("File Uploader")
          conn = Connection::Connection.new(url, nil, nil, site, file_uploader)

          Test.verify_settings conn,
                               :@site => site,
                               :@file_uploader => file_uploader
        end
      end
    end
  end
end
