require "spec_helper"

describe VCloudSdk::Connection::Connection, :min, :all do
  let(:url) { "https://10.147.0.0:8443" }
  let(:site) { double("site") }
  let(:file_uploader) { double("File Uploader") }

  describe "#initialize" do
    before do
      VCloudSdk::Config.configure(logger: logger)
    end

    context "Config logger is set to a log file" do
      let(:logger) { VCloudSdk::Test.logger }

      it "uses settings in input arguments" do
        rest_throttle = {
          min: 0,
          max: 1,
        }

        conn = described_class.new(url, nil, nil, site, file_uploader, rest_throttle)
        VCloudSdk::Test.verify_settings conn,
                                        :@site => site,
                                        :@file_uploader => file_uploader,
                                        :@rest_throttle => rest_throttle
      end

      it "uses default settings if not specified in input arguments" do
        conn = described_class.new(url, nil, nil, site, file_uploader)
        conn.instance_variable_get(:@rest_throttle).should
        eql VCloudSdk::Connection::Connection.const_get(:REST_THROTTLE)
      end
    end

    context "Config logger is set to STDOUT" do
      let(:logger) { Logger.new(STDOUT) }

      it "constructs rest logger" do
        conn = described_class.new(url, nil, nil, site, file_uploader)
        conn.instance_variable_get(:@rest_logger)
          .should eql logger
      end
    end
  end
end
