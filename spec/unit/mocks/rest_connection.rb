require_relative "rest_client"

module VCloudSdk
  module Mocks
    class RestConnection
      attr_reader :url

      def initialize(url)
        @url = url
        @rest_client = VCloudSdk::Mocks::RestClient.new(url)
      end

      def mock_connection
        VCloudSdk::Connection::Connection.new(@url, nil, nil, @rest_client)
      end
    end
  end
end
