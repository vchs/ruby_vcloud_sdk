module VCloudSdk
  module Test
    class ResponseMapping
      LINK_TO_RESPONSE = {
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
