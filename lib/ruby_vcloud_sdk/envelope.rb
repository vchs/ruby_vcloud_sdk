require_relative "infrastructure"

module VCloudSdk
  
  ##############################################################################
  # This class represents a catalog item in catalog.
  # It can be a vApp Template or media&other, 
  ##############################################################################
  class Envelope
    include Infrastructure
    
   
    ############################################################################
    # Initializes a Catalog Item object associated with a vCloud Session and the
    # the catalog item's link 
    # @param session   [Session] The client's session
    # @param link      [String]  The xml representation of catalog item
    ############################################################################
    def initialize(session, link)    
      @session = session
      @link = link
    end
    
    def ent
      entity_xml
    end    

    def os      
      entity_xml.operating_system
    end

    def disks      
      hardware_section = entity_xml.hardware_section
      internal_disks = []
      hardware_section.hard_disks.each do |disk|
        disk_link = disk.host_resource.attribute("disk")
        if disk_link.nil?
          internal_disks << VCloudSdk::InternalDisk.new(disk)
        end
      end
      internal_disks
    end
  end
  ##############################################################################
end
