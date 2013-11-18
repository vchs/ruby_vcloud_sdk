# Ruby VCloud SDK is a gem to simplify making vCloud Director API calls.
Copyright (c) VMware, Inc.

## Object Model

  Client
  
    find_vdc_by_name
    
    catalogs
    
    find_catalog_by_name

    create_catalog
    
    delete_catalog
    
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
  