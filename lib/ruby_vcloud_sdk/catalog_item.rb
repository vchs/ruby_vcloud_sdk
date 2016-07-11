require_relative "session"
require_relative "infrastructure"

module VCloudSdk
  
  ##############################################################################
  # This class represents a catalog item in catalog.
  # It can be a vApp Template or media&other, 
  ##############################################################################
  class CatalogItem
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

    ############################################################################
    # Return the name of the Catalog Item object 
    # @return      [String]  The name of the catalog item
    ############################################################################
    def name      
      entity_xml.entity[:name]
    end

    ############################################################################
    # Return the identifier of the Catalog Item object 
    # @return      [String]  The identifier of the catalog item
    ############################################################################
    def id      
      id = entity_xml.urn
      id.split(":")[3] 
    end

    ############################################################################
    # Return the description of the Catalog Item object 
    # @return      [String]  The description of the catalog item
    ############################################################################
    def description 
      entity_xml.description     
    end

    ############################################################################
    # Return the vApp template id of the Catalog Item object 
    # @return      [String]  The vApp template id of the catalog item
    ############################################################################
    def vapp_template_id
      entity_xml.entity[:href].split("/")[5]
    end     

    ############################################################################
    # Return the type of the Catalog Item object. It can be: 
    # @return      [String]  The type of the catalog item
    ############################################################################
    def type
      entity_xml.entity[:type]
    end

    ############################################################################
    # Return the vCloud href of the Catalog Item object. 
    # @return      [String]  The href of the catalog item
    ############################################################################
    def href
      entity_xml.entity[:href]
    end

    ############################################################################
    # Return the date of creation of the Catalog Item object. 
    # @return      [String]  The creation date of the catalog item
    ############################################################################
    def date
      entity_xml.date
    end
  end
end
