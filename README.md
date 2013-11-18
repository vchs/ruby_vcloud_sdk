## Ruby VCloud SDK is a gem to simplify making vCloud Director API calls.
Copyright (c) VMware, Inc.

## Object Model

  Client
  
    find_vdc_by_name
      success: returns VDC object
      failure: If VDC does not exist, it throws 'ObjectNotFoundError' exception

    catalogs
      success: returns array of Catalog objects
      failure: If no catalog, it returns empty array

    find_catalog_by_name
      success: returns Catalog object
      failure: If catalog does not exist, it returns nil object

    create_catalog
      success: returns XML response from post rest call
      failure: Upon error, it throws 400 RestClient::BadRequest exception

    delete_catalog
     success: returns XML response from delete rest call
     failure: If catalog does not not exist, it throws 'ObjectNotFoundError' exception
              Upon error, it throws 400 RestClient::BadRequest exception
    
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
     
     add_item
     
     find_vapp_template_by_name
     
  Network
  
     ip_ranges
     
     allocated_ips
     
  VApp
  
     delete
     
     power_on
     
     power_off
     
  VdcStorageProfile
  
     available_storage
  