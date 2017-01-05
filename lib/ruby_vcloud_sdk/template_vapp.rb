require_relative "session"
require_relative "infrastructure"
require_relative "envelope"

module VCloudSdk
  
  ##############################################################################
  # This class represents a catalog item in catalog.
  # It can be a vApp Template or media&other, 
  ##############################################################################
  class TemplateVapp
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
    
    def ovf_descriptor      
      ovf = VCloudSdk::Envelope.new(@session, entity_xml.ovf_link)
      ovf.ent
    end

    def disks
      ovf = VCloudSdk::Envelope.new(@session, entity_xml.ovf_link)
      ovf.disks
    end

    def operating_system      
      ovf = VCloudSdk::Envelope.new(@session, entity_xml.ovf_link)
      ovf.os
    end

    def vm_link
      entity_xml.vm_link
    end
  end
  ##############################################################################
end
