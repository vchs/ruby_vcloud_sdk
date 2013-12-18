require "spec_helper"
require_relative "mocks/client_response"
require_relative "mocks/response_mapping"
require_relative "mocks/rest_client"
require "nokogiri/diff"

describe VCloudSdk::Session do
  let(:logger) { VCloudSdk::Test.logger }
  let(:url) { VCloudSdk::Test::Response::URL }
  let(:username) { "cfadmin" }
  let(:password) { "akimbi" }
  let(:conn) { double("Connection") }
  let(:options) { {} }
  let(:session) do
    VCloudSdk::Xml::WrapperFactory
      .wrap_document(VCloudSdk::Test::Response::SESSION)
  end
  let!(:mock_connection) do
    VCloudSdk::Test.mock_connection(logger, url)
  end

  describe "#initialize" do
    it "sets up connection successfully" do
      VCloudSdk::Connection::Connection
        .should_receive(:new)
        .once
        .and_return(mock_connection)
      described_class.new(url, username, password, options)
    end

    it "uses default settings if not specified in input arguments" do
      VCloudSdk::Connection::Connection
        .should_receive(:new).once.and_return conn

      conn.should_receive(:connect)
        .with(username, password)
        .once
        .ordered
        .and_return(session)

      session = described_class.new(nil, username, password, options)
      VCloudSdk::Test.verify_settings session,
                                      :@retries => VCloudSdk::Session
                                        .const_get(:RETRIES),
                                      :@time_limit => VCloudSdk::Session
                                        .const_get(:TIME_LIMIT_SEC),
                                      :@delay => VCloudSdk::Session
                                        .const_get(:DELAY)
    end

    it "uses settings in input arguments" do
      VCloudSdk::Connection::Connection
        .should_receive(:new).once.and_return conn

      conn.should_receive(:connect)
        .with(username, password)
        .once
        .ordered
        .and_return(session)

      retries = {
        default: 5,
        upload_vapp_files: 7,
        cpi: 1
      }

      time_limit_sec = {
        default: 120,
        delete_vapp_template: 120,
        delete_vapp: 120,
        delete_media: 120,
        instantiate_vapp_template: 300,
        power_on: 600,
        power_off: 600,
        undeploy: 720,
        process_descriptor_vapp_template: 300,
        http_request: 240
      }

      options = {
        retries: retries,
        time_limit_sec: time_limit_sec
      }

      session = described_class.new(nil, username, password, options)
      VCloudSdk::Test.verify_settings session,
                                      :@retries => retries,
                                      :@time_limit => time_limit_sec
    end
  end

  describe "#org" do
    subject { VCloudSdk::Test.mock_session(logger, url) }

    it "has correct name" do
      subject.org.name.should eql VCloudSdk::Test::Response::ORGANIZATION
    end

    it "populates exception upon failure" do
      error_msg = "400 Bad Request"
      session_xml_obj = VCloudSdk::Xml::WrapperFactory
        .wrap_document(VCloudSdk::Test::Response::SESSION)
      subject
        .send(:connection)
        .stub(:get)
        .with(session_xml_obj.organization)
        .and_raise(error_msg)
      expect { subject.org }.to raise_error(error_msg)
    end
  end
end
