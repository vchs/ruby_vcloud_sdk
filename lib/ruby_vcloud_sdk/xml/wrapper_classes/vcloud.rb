module VCloudSdk
  module Xml

    class VCloud < Wrapper
      def organizations
        get_nodes('OrganizationReference')
      end

      def organization
        # TODO: check and make sure that
        # there is only one "OrganizationReference" node in response
        get_nodes('OrganizationReference').first
      end
    end

  end
end
