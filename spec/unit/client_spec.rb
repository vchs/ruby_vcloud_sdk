require "spec_helper"
require_relative "mocks/client_response"
require_relative "mocks/response_mapping"
require "nokogiri/diff"

module VCloudSdk
  module Test
    logger = Config.logger

    describe Client, :min, :all do

      let(:url) { "https://10.147.0.0:8443" }
      let(:username) { "cfadmin" }
      let(:password) { "akimbi" }
      let(:response_mapping) { response_mapping }

      def build_url
        url + @resource
      end

      def mock_rest_connection
        rest_client = double("Rest Client")
        rest_client.stub(:get) do |headers|
          ResponseMapping.get_mapping(:get, build_url).call(build_url,
                                                            headers)
        end
        rest_client.stub(:post) do |data, headers|
          ResponseMapping.get_mapping(:post, build_url).call(build_url,
                                                             data, headers)
        end
        rest_client.stub(:[]) do |value|
          @resource = value
          rest_client
        end

        conn = Connection::Connection.new(url, nil, nil, rest_client)
      end

      describe ".initialize" do
        it "set up connection successfully" do
          Config.configure(
              logger: logger,
              rest_throttle: { min: 0, max: 1 })

          conn = mock_rest_connection
          Connection::Connection.should_receive(:new).with(anything, anything).once.and_return conn
          Client.new(url, username, password, {}, logger)
        end

        it "use default settings if not specified in input arguments" do
          conn = double("Connection")
          root_session = Xml::WrapperFactory.wrap_document(
              Response::SESSION)
          vcloud_response = Xml::WrapperFactory.wrap_document(
              Response::VCLOUD_RESPONSE)
          admin_org_response = Xml::WrapperFactory.wrap_document(
              Response::ADMIN_ORG_RESPONSE)

          Connection::Connection.should_receive(:new).with(anything, anything).once.and_return conn
          conn.should_receive(:connect).with(username, password).once.ordered.and_return(
              root_session)
          conn.should_receive(:get).with(root_session.admin_root).once.ordered.and_return(
              vcloud_response)
          conn.should_receive(:get).with(vcloud_response.organization).once.ordered.and_return(
              admin_org_response)
          client = Client.new(nil, username, password, {}, logger)
          Test.verify_settings client,
                               :@retries => Client.const_get(:RETRIES),
                               :@time_limit => Client.const_get(:TIME_LIMIT_SEC)

          Config.rest_throttle.should eq Client.const_get(:REST_THROTTLE)
        end

        it "use settings in input arguments" do
          conn = double("Connection")
          root_session = Xml::WrapperFactory.wrap_document(
              Response::SESSION)
          vcloud_response = Xml::WrapperFactory.wrap_document(
              Response::VCLOUD_RESPONSE)
          admin_org_response = Xml::WrapperFactory.wrap_document(
              Response::ADMIN_ORG_RESPONSE)

          Connection::Connection.should_receive(:new).with(anything, anything).once.and_return conn
          conn.should_receive(:connect).with(username, password).once.ordered.and_return(
              root_session)
          conn.should_receive(:get).with(root_session.admin_root).once.ordered.and_return(
              vcloud_response)
          conn.should_receive(:get).with(vcloud_response.organization).once.ordered.and_return(
              admin_org_response)

          retries =
              {
                  default: 5,
                  upload_vapp_files: 7,
                  cpi: 1
              }

          time_limit_sec =
              {
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

          rest_throttle =
              {
                  min: 0,
                  max: 1
              }

          options = { retries: retries, time_limit_sec: time_limit_sec, rest_throttle: rest_throttle }
          client = Client.new(nil, username, password,
                              options, logger)
          Test.verify_settings client,
                               :@retries => retries,
                               :@time_limit => time_limit_sec

          Config.rest_throttle.should eq rest_throttle
        end
      end
    end
  end
end
