module VCloudSdk
  module Test
    class ResponseMapping
      LINK_TO_RESPONSE = {
          get: {
            Test::Response::SUPPORTED_VERSIONS_LINK =>
              lambda do |url, headers|
                Test::Response::SUPPORTED_VERSIONS_RESPONSE
              end,
            Test::Response::ORG_LINK =>
              lambda do |url, headers|
                Test::Response::ORG_RESPONSE
              end,
            Test::Response::VDC_LINK =>
              lambda do
              |url, headers| Test::Response::VDC_RESPONSE
              end,
            Test::Response::ORG_VDC_STORAGE_PROFILE_LINK =>
              lambda do
              |url, headers| Test::Response::ORG_VDC_STORAGE_PROFILE_RESPONSE
              end,
          },
          post: {
            Test::Response::LOGIN_LINK =>
              lambda do |url, data, headers|
                session_object = Test::Response::SESSION

                def session_object.cookies
                  { 'vcloud-token' => 'fake-cookie' }
                end

                session_object
              end,
            Test::Response::CATALOG_CREATE_LINK =>
              lambda do |url, data, headers|
                fail "400 Bad Request" if data.include?("name=\"#{VCloudSdk::Test::Response::CATALOG_NAME}\"")

                Test::Response::CATALOG_CREATE_RESPONSE
              end,
          },
          delete: {
            Test::Response::CATALOG_DELETE_LINK =>
              lambda do |url, headers|
                nil
              end,
          },
      }

      private_constant :LINK_TO_RESPONSE

      def self.get_mapping(http_method, url)
        mapping = LINK_TO_RESPONSE[http_method][url]
        if mapping.nil?
          err_msg = "Response mapping not found for #{http_method} and #{url}"
          Config.logger.error(err_msg)
          fail err_msg
        end

        mapping
      end
    end
  end
end
