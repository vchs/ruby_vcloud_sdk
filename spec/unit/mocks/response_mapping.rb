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
              lambda do |url, headers|
                Test::Response::VDC_RESPONSE
              end,
            Test::Response::ORG_VDC_STORAGE_PROFILE_LINK =>
              lambda do |url, headers|
                case (options[:storage_profile])
                when :empty
                  Test::Response::EMPTY_ORG_VDC_STORAGE_PROFILE_RESPONSE
                when :non_empty
                  Test::Response::ORG_VDC_STORAGE_PROFILE_RESPONSE
                end
              end,
            Test::Response::ORG_VDC_ENCODED_STORAGE_PROFILE_LINK =>
              lambda do |url, headers|
                Test::Response::ORG_VDC_STORAGE_PROFILE_RESPONSE
              end,
            Test::Response::CATALOG_LINK =>
              lambda do |url, headers|
                case (options[:catalog_state])
                when :not_added
                  Test::Response::CATALOG_RESPONSE
                when :added
                  Test::Response::CATALOG_ITEM_ADDED_RESPONSE
                end
              end,
            Test::Response::EXISTING_VAPP_TEMPLATE_CATALOG_ITEM_LINK =>
              lambda do |url, headers|
                Test::Response::EXISTING_VAPP_TEMPLATE_CATALOG_ITEM_RESPONSE
              end,
            Test::Response::EXISTING_MEDIA_CATALOG_ITEM_LINK  =>
              lambda do |url, headers|
                Test::Response::EXISTING_MEDIA_CATALOG_ITEM
              end,
            Test::Response::VAPP_TEMPLATE_LINK =>
              lambda do |url, headers|
                case (options[:vapp_state])
                when :ovf_uploaded
                  Test::Response::VAPP_TEMPLATE_NO_DISKS_RESPONSE
                when :nothing
                  Test::Response::VAPP_TEMPLATE_UPLOAD_OVF_WAITING_RESPONSE
                when :disks_uploaded
                  Test::Response::VAPP_TEMPLATE_UPLOAD_COMPLETE
                when :disks_upload_failed
                  Test::Response::VAPP_TEMPLATE_UPLOAD_FAILED
                when :finalized
                  Test::Response::VAPP_TEMPLATE_READY_RESPONSE
                end
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
            Test::Response::VDC_VAPP_UPLOAD_LINK =>
              lambda do |url, data, headers|
                set_option vapp_state: :nothing
                Test::Response::VAPP_TEMPLATE_UPLOAD_OVF_WAITING_RESPONSE
              end,
            Test::Response::CATALOG_ADD_ITEM_LINK =>
              lambda do |url, data, headers|
                case (Xml::WrapperFactory.wrap_document(data))
                when Xml::WrapperFactory.wrap_document(
                  Test::Response::CATALOG_ADD_VAPP_REQUEST)
                  Test::Response::CATALOG_ADD_ITEM_RESPONSE
                when Xml::WrapperFactory.wrap_document(
                  Test::Response::MEDIA_ADD_TO_CATALOG_REQUEST)
                  Test::Response::MEDIA_ADD_TO_CATALOG_RESPONSE
                else
                  Config.logger.error %Q{
                    Response mapping not found for POST and #{url} and
                    #{data}
                  }
                  fail "Response mapping not found."
                end
              end,
          },
          delete: {
            Test::Response::CATALOG_DELETE_LINK =>
              lambda do |url, headers|
                nil
              end,
            Test::Response::EXISTING_VAPP_TEMPLATE_CATALOG_ITEM_LINK =>
              lambda do |url, headers|
                nil
              end,
            Test::Response::EXISTING_MEDIA_CATALOG_ITEM_LINK  =>
              lambda do |url, headers|
                nil
              end,
          },
          put: {
            Test::Response::VAPP_TEMPLATE_UPLOAD_OVF_LINK =>
              lambda do |url, data, headers|
                set_option vapp_state: :ovf_uploaded
                ""
              end,
          }
      }

      private_constant :LINK_TO_RESPONSE

      class << self
        attr_accessor :options

        def set_option(option)
          @options = @options || {}
          @options.merge!(option)
        end

        def get_mapping(http_method, url)
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
end
