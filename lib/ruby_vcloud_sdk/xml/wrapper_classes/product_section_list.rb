require "forwardable"

module VCloudSdk
  module Xml
    class ProductSectionList < Wrapper
      extend Forwardable
      def_delegator :production_section, :add_property

      def production_section
        get_nodes("ProductSection", nil, true, OVF).first
      end
    end
  end
end
