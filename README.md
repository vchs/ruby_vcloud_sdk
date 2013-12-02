## Ruby VCloud SDK is a gem to simplify making vCloud Director API calls.
Copyright (c) VMware, Inc.

## Object Model

  Client
  
    find_vdc_by_name
      returns: VDC object matching name
      throws:
        'ObjectNotFoundError' when VDC with the name does not exist
        'RestClient::BadRequest' for un-expected errors

    catalogs
      returns: array of catalog objects
      throws:
        'RestClient::BadRequest' for un-expected errors

    find_catalog_by_name
      returns:
        catalog object matching name
      throws:
        'RuntimeError' when catalog with the name does not exist
        'RestClient::BadRequest' for un-expected errors

    create_catalog
      returns: catalog object created
      throws:
        'RestClient::BadRequest' for un-expected errors

    delete_catalog
      returns: nil
      throws:
        'ObjectNotFoundError' when catalog with the name does not exist
        'RestClient::BadRequest' for un-expected errors
    
  VDC
    
    storage_profiles
    
    find_storage_profile_by_name
    
    vapps
    
    find_vapp_by_name
    
    resources
    
    networks
    
    find_network_by_name
    
  Catalog
  
     items
     
     delete_all_catalog_items
     
     upload_vapp_template

     find_item
        returns: catalog item matching name and type
        throws:
          'ObjectNotFoundError' when an item matching the name and type is not found
          'RestClient::BadRequest' for un-expected errors
     
     add_item
     
     find_vapp_template_by_name

     upload_media
        returns: catalog item uploaded
        throws:
          'RuntimeError' when strorage profile with the name does not exist or media file matching name already exists
          'RestClient::BadRequest' for un-expected errors
     
  Network
  
     ip_ranges
     
     allocated_ips
     
  VApp
  
     delete
     
     power_on
     
     power_off
     
  VdcStorageProfile
  
     available_storage
  