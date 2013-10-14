require 'spec_helper'
require_relative 'client_response'

module VCloudSdk
  logger = Config.logger
  Config.configure(
  {
      logger: logger,
      rest_throttle: { min: 0, max: 1 }
  })

  response_mapping = {
      get: {
          Test::Response::ADMIN_VCLOUD_LINK =>
              lambda do |url, headers|
                Test::Response::VCLOUD_RESPONSE
              end,
          Test::Response::ADMIN_ORG_LINK =>
              lambda do |url, headers|
                Test::Response::ADMIN_ORG_RESPONSE
              end
      },
      post: {
          Test::Response::LOGIN_LINK =>
              lambda do |url, data, headers|
                session_object = Test::Response::SESSION

                def session_object.cookies
                  { 'vcloud-token' => 'fake-cookie' }
                end

                session_object
              end
      }
  }

  def response_mapping.get_mapping(http_method, url)
    mapping = self[http_method][url]
    if mapping.nil?
      err_msg = "Response mapping not found for #{http_method} and #{url}"
      Config.logger.error(err_msg)
      raise err_msg
    end

    mapping
  end

  describe Client, :min, :all do

    let(:url) { 'https://10.147.0.0:8443' }
    let(:username) { 'cfadmin' }
    let(:password) { 'akimbi' }
    let(:response_mapping) { response_mapping }

    def build_url
      url + @resource
    end

    def mock_rest_connection
      rest_client = double('Rest Client')
      rest_client.stub(:get) do |headers|
        response_mapping.get_mapping(:get, build_url).call(build_url, headers)
      end
      rest_client.stub(:post) do |data, headers|
        response_mapping.get_mapping(:post, build_url).call(build_url, data,
                                                            headers)
      end
      rest_client.stub(:[]) do |value|
        @resource = value
        rest_client
      end

      conn = Connection::Connection.new(url, nil, nil, rest_client)
    end

    describe '.initialize' do
      it 'set up connection successfully' do
        conn = mock_rest_connection
        Connection::Connection.stub(:new).with(anything, anything).and_return conn
        Client.new(url, username, password, {}, logger)
      end
    end
  end
end
