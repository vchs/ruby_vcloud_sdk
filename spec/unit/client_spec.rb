require 'spec_helper'
require_relative 'mocks/client_response'
require_relative 'mocks/response_mapping'

module VCloudSdk
  logger = Config.logger
  Config.configure(
      logger: logger,
      rest_throttle: { min: 0, max: 1 })

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
        Test::ResponseMapping.get_mapping(:get, build_url).call(build_url,
                                                                headers)
      end
      rest_client.stub(:post) do |data, headers|
        Test::ResponseMapping.get_mapping(:post, build_url).call(build_url,
                                                                 data, headers)
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
