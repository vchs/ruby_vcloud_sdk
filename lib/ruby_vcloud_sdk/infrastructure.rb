require_relative "vdc"
require_relative "catalog"
require_relative "session"

module VCloudSdk
  # Shared functions by classes such as Client, Catalog and VDC
  # Make sure instance variables @session and @connection are available
  module Infrastructure

    def find_vdc_by_name(name)
      vdc_link = @session.org.vdc_link(name)
      fail ObjectNotFoundError, "VDC #{name} not found" unless vdc_link
      VCloudSdk::VDC.new(@session, @connection.get(vdc_link))
    end

    def catalogs
      @session.org.catalogs.map do |catalog|
        VCloudSdk::Catalog.new(@session, catalog)
      end
    end

    def find_catalog_by_name(name)
      catalogs.each do |catalog|
        return catalog if catalog.name == name
      end

      nil
    end

  end
end
