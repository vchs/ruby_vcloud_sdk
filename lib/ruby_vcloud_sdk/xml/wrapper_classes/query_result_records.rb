module VCloudSdk
  module Xml
    class QueryResultRecords < Wrapper
      # Reference: http://pubs.vmware.com/vcd-55/index.jsp?topic=%2Fcom.vmware.vcloud.api.reference.doc_55%2Fdoc%2Ftypes%2FQueryResultOrgVdcStorageProfileRecordType.html
      def org_vdc_storage_profile_records
        get_nodes("OrgVdcStorageProfileRecord")
      end

      def edge_gateway_records
        get_nodes("EdgeGatewayRecord")
      end

      def right_records
        get_nodes("RightRecord")
      end
    end
  end
end
