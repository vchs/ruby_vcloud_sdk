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

    list_catalogs
      returns: array of catalog names
      throws:
        'RestClient::BadRequest' for un-expected errors

    find_catalog_by_name
      returns:
        catalog object matching name
      throws:
        'ObjectNotFoundError' when catalog with the name does not exist
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
      returns: array of storage profile objects
      throws:
        'RestClient::BadRequest' for un-expected errors

    list_storage_profiles
      returns: array of storage profile names
      throws:
        'RestClient::BadRequest' for un-expected errors
    
    find_storage_profile_by_name
      returns:
        storage profile object matching name
      throws:
        'ObjectNotFoundError' when storage profile with the name does not exist
        'RestClient::BadRequest' for un-expected errors
    
    vapps
      returns: array of vapp objects
      throws:
        'RestClient::BadRequest' for un-expected errors

    list_vapps
      returns: array of vapp names
      throws:
        'RestClient::BadRequest' for un-expected errors
    
    find_vapp_by_name
      returns:
        vapp object matching name
      throws:
        'ObjectNotFoundError' when vapp with the name does not exist
        'RestClient::BadRequest' for un-expected errors

    resources
    
    networks
      returns: array of network objects
      throws:
        'RestClient::BadRequest' for un-expected errors

    list_networks
      returns: array of network names
      throws:
        'RestClient::BadRequest' for un-expected errors
    
    find_network_by_name
      returns:
        network object matching name
      throws:
        'ObjectNotFoundError' when network with the name does not exist
        'RestClient::BadRequest' for un-expected errors

    disks
      returns: array of disk objects
      throws:
        'RestClient::BadRequest' for un-expected errors

    list_disks
      returns: array of disk names
      throws:
        'RestClient::BadRequest' for un-expected errors

    find_disks_by_name
      returns:
        array of disk objects matching name
      throws:
        'ObjectNotFoundError' when disk with the name does not exist
        'RestClient::BadRequest' for un-expected errors
    
  Catalog
  
     items
       returns: array of catalog item objects
       throws:
         'RestClient::BadRequest' for un-expected errors

     list_items
       returns: array of catalog item names
       throws:
         'RestClient::BadRequest' for un-expected errors
     
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
          'CloudError' when media file matching name already exists
          'ObjectNotFoundError' when storage profile with the name does not exist
          'RestClient::BadRequest' for un-expected errors
     
  Network
  
     ip_ranges
        returns: IpRanges object
        throws:
          'RestClient::BadRequest' for un-expected errors
     
     allocated_ips
        returns: array of strings
        throws:
          'RestClient::BadRequest' for un-expected errors
     
  VApp
  
     delete
        returns: task object
        throws:
          'CloudError' if VApp is powered on
          'RestClient::BadRequest' for un-expected errors
     
     power_on
        returns: task object
        throws:
          'CloudError' if power_on_link of VApp is missing
          'RestClient::BadRequest' for un-expected errors
     
     power_off
        returns: task object
        throws:
          'CloudError' if power_off_link of VApp is missing
          'VappSuspendedError' if VApp is suspended
          'RestClient::BadRequest' for un-expected errors

     recompose_from_vapp_template
        returns: recomposed vapp
        throws:
          'CloudError' when vapp is powered on
          'ObjectNotFoundError' when catalog with the name does not exist
          'ObjectNotFoundError' when vapp template with the name does not exist
          'RestClient::BadRequest' for un-expected errors

     vms
       returns: array of vm objects
       throws:
         'RestClient::BadRequest' for un-expected errors

     list_vms
       returns: array of vm names
       throws:
         'RestClient::BadRequest' for un-expected errors

     find_vm_by_name
       returns: VM object
       throws:
         'ObjectNotFoundError' when VM with the name does not exist
         'RestClient::BadRequest' for un-expected errors

     remove_vm_by_name
       returns: parent VApp object
       throws:
         'ObjectNotFoundError' when VM with the name does not exist
         'CloudError' when VApp is in status of 'POWERED_ON' and can not be recomposed
         'RestClient::BadRequest' for un-expected errors

  VM

     independent_disks
       returns: array of disk objects
       throws:
         'RestClient::BadRequest' for un-expected errors

     list_disks
       returns: names of disks on vm (in parentheses it shows the name of independent disk)
       throws:
         'RestClient::BadRequest' for un-expected errors

     attach_disk
       returns: task object
       throws:
         'CloudError' if disk is already attached
         'RestClient::BadRequest' for un-expected errors

     detach_disk
       returns: task object
       throws:
         'VmSuspendedError' if containing vApp is suspended
         'CloudError' if disk is not attached or attached to other VM
         'RestClient::BadRequest' for un-expected errors

     status
       returns: string object
       throws:
         'CloudError' if status code is invalid
         'RestClient::BadRequest' for un-expected errors

     power_on
       returns: task object
       throws:
         'CloudError' if power_on_link of VM is missing
         'RestClient::BadRequest' for un-expected errors

     power_off
       returns: task object
       throws:
         'CloudError' if power_off_link of VM is missing
         'VmSuspendedError' if VM is suspended
         'RestClient::BadRequest' for un-expected errors

     insert_media
       returns: task object
       throws:
         'ObjectNotFoundError' if when catalog with the name does not exist
         'ObjectNotFoundError' if when media with the name does not exist
         'RestClient::BadRequest' for un-expected errors

     eject_media
       returns: task object
       throws:
         'ObjectNotFoundError' if when catalog with the name does not exist
         'ObjectNotFoundError' if when media with the name does not exist
         'RestClient::BadRequest' for un-expected errors

  VdcStorageProfile
  
     available_storage
       returns:
         integer number of available storage in MB, i.e. storageLimitMB - storageUsedMB
         -1 if 'storageLimitMB' is 0

  EdgeGateway

     public_ips:
       returns: IpRanges object
       throws:
         'RestClient::BadRequest' for un-expected errors
  