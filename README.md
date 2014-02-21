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

    delete_catalog_by_name
      parameters:
        name (String): name of catalog
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

    create_disk
      parameters:
        name (String): name of disk
        size_mb (Integer): disk size in megabyte
        vm (VCloudSdk::VM, optional): VM that to add disk locality to
        bus_type (String, optional): bus type of disk, defaults to "scsi"
        bus_sub_type (String, optional): bus sub type of disk, defaults to "lsilogic"
      returns: Disk object created
      throws:
        'CloudError' when size_mb is less than or equal to 0
        'CloudError' when bus_type is invalid
        'CloudError' when bus_sub_type is invalid
        'RestClient::BadRequest' for un-expected errors

    delete_disk_by_name
      parameters:
        name (String): name of disk
      returns: nil
      throws:
        'CloudError' when more than one disks matching the name exist
        'CloudError' when disk is attached to vm
        'RestClient::BadRequest' for un-expected errors

    delete_all_disks_by_name
      parameters:
        name (String): name of disk
      returns: nil
      throws:
        'CloudError' when any disk deletion failure occurs
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
     
     find_item
        returns: catalog item matching name and type
        throws:
          'ObjectNotFoundError' when an item matching the name and type is not found
          'RestClient::BadRequest' for un-expected errors

     item_exists?
        returns: boolean
        throws:
          'RestClient::BadRequest' for un-expected errors
     
     delete_item_by_name_and_type
        parameters:
          name (String): name of item
          type (String, optional): type of item - "application/vnd.vmware.vcloud.vAppTemplate+xml" or "application/vnd.vmware.vcloud.media+xml"
        returns: nil
        throws:
          'ObjectNotFoundError' when an item matching the name and type is not found
          'RestClient::BadRequest' for un-expected errors

     delete_all_items
        returns: nil
        throws:
          'RestClient::BadRequest' for un-expected errors

     upload_media
        returns: catalog item uploaded
        throws:
          'CloudError' when media file matching name already exists
          'ObjectNotFoundError' when storage profile with the name does not exist
          'RestClient::BadRequest' for un-expected errors

     find_media_by_name
        parameters:
          name (String): name of media
        returns: media catalog item matching name
        throws:
          'ObjectNotFoundError' when an item matching the name and type is not found
          'RestClient::BadRequest' for un-expected error

     upload_vapp_template
         parameters:
           vdc_name (String): name of vdc
           template_name (String): name of vapp template
           directory (String): path of vapp template directory
           storage_profile_name (String, optional): name of storage profile to upload vapp template to
        returns: vapp template catalog item uploaded
        throws:
          'CloudError' when vapp template matching name already exists
          'ApiTimeoutError' if uploading vapp files times out
          'CloudError' when uploading vapp template task is not successful
          'RestClient::BadRequest' for un-expected error

     find_vapp_template_by_name
        parameters:
          name (String): name of vapp template
        returns: vapp template catalog item matching name
        throws:
          'ObjectNotFoundError' when an item matching the name and type is not found
          'RestClient::BadRequest' for un-expected error

     instantiate_vapp_template
         parameters:
           template_name (String): name of vapp template
           vdc_name (String): name of vdc
           vapp_name (String): name of vapp
           description (String, optional): description of vapp template
         returns: vapp object instantiated
         throws:
           'ApiError' when instantiating vapp template task is not successful
           'RestClient::BadRequest' for un-expected error
     
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
  