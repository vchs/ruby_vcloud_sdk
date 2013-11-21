module VCloudSdk
  module Xml
    class UploadVAppTemplateParams < Wrapper
      def storage_profile=(storage_profile)
        add_child(storage_profile) unless storage_profile.nil?
      end
    end
  end
end
