module VCloudSdk
  # Shared functions by classes VM and VApp
  module Powerable
    def status
      status_code = entity_xml[:status].to_i
      Xml::RESOURCE_ENTITY_STATUS.each_pair do |k, v|
        return k.to_s if v == status_code
      end

      fail CloudError,
           "Fail to find corresponding status for code '#{status_code}'"
    end

    private

    def is_status?(target, status)
      target[:status] == Xml::RESOURCE_ENTITY_STATUS[status].to_s
    end
  end
end
