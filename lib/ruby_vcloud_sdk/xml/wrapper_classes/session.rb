module VCloudSdk
  module Xml

    class Session < Wrapper
      def organization
        get_nodes(XML_TYPE[:LINK],
                  { type: VCloudSdk::Xml::MEDIA_TYPE[:ORGANIZATION] }).first
      end

      def entity_resolver
        get_nodes(XML_TYPE[:LINK],
                  { type: VCloudSdk::Xml::MEDIA_TYPE[:ENTITY] }).first
      end
    end

  end
end
