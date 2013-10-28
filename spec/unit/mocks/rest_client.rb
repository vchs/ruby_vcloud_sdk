module VCloudSdk
  module Mocks
    class RestClient
      attr_reader :url

      def initialize(url)
        @url = url
      end

      def [](value)
        @resource = value
        self
      end

      def get(headers = {})
        VCloudSdk::Test::ResponseMapping
          .get_mapping(:get, build_url).call(build_url, headers)
      end

      def post(payload, headers = {})
        VCloudSdk::Test::ResponseMapping
          .get_mapping(:post, build_url).call(build_url, payload, headers)
      end

      def delete(headers = {})
        VCloudSdk::Test::ResponseMapping
          .get_mapping(:delete, build_url).call(build_url, headers)
      end

      private

      def build_url
        @url + @resource
      end
    end
  end
end
