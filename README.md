# Ruby VCloud SDK is a gem to simplify making vCloud Director API calls.
Copyright (c) VMware, Inc.

## Object Structure
=================


    Client -> VDC   -> Vapp     -> Vm     -> Nic 
                                          -> Disk
                                -> Network
                    -> Network  -> IpRanges 
                    -> Disk
                    -> Resource
                    -> Edge Gateway -> IpRanges
                    -> Storage Profile
           -> Catalog -> Catalog Item
           -> RightRecord

## Object Model
===============

  Client
  ------
  
    find_vdc_by_name
      parameters:
        name (String): name of VDC
      returns: VDC object matching name
      throws:
        'ObjectNotFoundError' when VDC with the name does not exist
        'RestClient::BadRequest' for un-expected errors

    vdc_exists?
      parameters:
        name (String): name of VDC
      returns: boolean
      throws:
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
      returns: Client object
      throws:
        'ObjectNotFoundError' when catalog with the name does not exist
        'RestClient::BadRequest' for un-expected errors

    right_records
      returns: array of RightRecord objects
      throws:
        'RestClient::BadRequest' for un-expected errors
    
  VDC
  ---
    
    storage_profiles
      returns: array of storage profile objects
      throws:
        'RestClient::BadRequest' for un-expected errors

    list_storage_profiles
      returns: array of storage profile names
      throws:
        'RestClient::BadRequest' for un-expected errors
    
    find_storage_profile_by_name
      parameters:
        name (String): name of storage profile
      returns:
        storage profile object matching name
      throws:
        'ObjectNotFoundError' when storage profile with the name does not exist
        'RestClient::BadRequest' for un-expected errors

    storage_profile_exists?
      parameters:
        name (String): name of storage profile
      returns: boolean
      throws:
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
      parameters:
        name (String): name of vapp
      returns:
        vapp object matching name
      throws:
        'ObjectNotFoundError' when vapp with the name does not exist
        'RestClient::BadRequest' for un-expected errors

    find_vapp_by_id
      parameters:
        id (String): id of vapp
      returns:
        vapp object matching id
      throws:
        'ObjectNotFoundError' when vapp with the id does not exist
        'RestClient::BadRequest' for un-expected errors

    vapp_exists?
      parameters:
        name (String): name of vapp
      returns: boolean
      throws:
        'RestClient::BadRequest' for un-expected errors

    edge_gateways
      returns: array of EdgeGateway objects
      throws:
        'RestClient::BadRequest' for un-expected errors

    resources
      returns: Resources object
      throws:
        'RestClient::BadRequest' for un-expected errors
    
    networks
      returns: array of network objects
      throws:
        'RestClient::BadRequest' for un-expected errors

    list_networks
      returns: array of network names
      throws:
        'RestClient::BadRequest' for un-expected errors
    
    find_network_by_name
      parameters:
        name (String): name of network
      returns:
        network object matching name
      throws:
        'ObjectNotFoundError' when network with the name does not exist
        'RestClient::BadRequest' for un-expected errors

    network_exists?
      parameters:
        name (String): name of network
      returns: boolean
      throws:
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
      parameters:
        name (String): name of disk
      returns:
        array of disk objects matching name
      throws:
        'ObjectNotFoundError' when disk with the name does not exist
        'RestClient::BadRequest' for un-expected errors

    disk_exists?
      parameters:
        name (String): name of disk
      returns: boolean
      throws:
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
      returns: VDC object
      throws:
        'CloudError' when more than one disks matching the name exist
        'CloudError' when disk is attached to vm
        'RestClient::BadRequest' for un-expected errors

    delete_all_disks_by_name
      parameters:
        name (String): name of disk
      returns: VDC object
      throws:
        'CloudError' when any disk deletion failure occurs
        'RestClient::BadRequest' for un-expected errors

  Catalog
  -------
  
     items
       returns: array of catalog item objects
       throws:
         'RestClient::BadRequest' for un-expected errors

     list_items
       returns: array of catalog item names
       throws:
         'RestClient::BadRequest' for un-expected errors
     
    find_item
      parameters:
        name (String): name of item
        type (String, optional): type of item - "application/vnd.vmware.vcloud.vAppTemplate+xml" or "application/vnd.vmware.vcloud.media+xml"
      returns: catalog item matching name and type
      throws:
        'ObjectNotFoundError' when an item matching the name and type is not found
        'RestClient::BadRequest' for un-expected errors

    item_exists?
      parameters:
        name (String): name of item
        type (String, optional): type of item - "application/vnd.vmware.vcloud.vAppTemplate+xml" or "application/vnd.vmware.vcloud.media+xml"

      returns: boolean
      throws:
        'RestClient::BadRequest' for un-expected errors
     
     delete_item_by_name_and_type
        parameters:
          name (String): name of item
          type (String, optional): type of item - "application/vnd.vmware.vcloud.vAppTemplate+xml" or "application/vnd.vmware.vcloud.media+xml"
        returns: Catalog object
        throws:
          'ObjectNotFoundError' when an item matching the name and type is not found
          'RestClient::BadRequest' for un-expected errors

     delete_all_items
        returns: Catalog object
        throws:
          'RestClient::BadRequest' for un-expected errors

    upload_media
      parameters:
        vdc_name (String): name of vdc
        media_name (String): name of media
        file (String): path of media file
        storage_profile_name (String, optional): name of storage profile to upload vapp template to
        image_type (String, optional): type of image file
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
  -------
  
     ip_ranges
        returns: IpRanges object
        throws:
          'RestClient::BadRequest' for un-expected errors
     
     allocated_ips
        returns: array of strings
        throws:
          'RestClient::BadRequest' for un-expected errors
     
  VApp
  ----

     id
       returns: vApp's id

     name
       returns: vApp's name

     status:
        returns: vApp's status
  
     delete
        returns: nil
        throws:
          'CloudError' if VApp is powered on
          'RestClient::BadRequest' for un-expected errors
     
     power_on
        returns: VApp object
        throws:
          'CloudError' if power_on_link of VApp is missing
          'RestClient::BadRequest' for un-expected errors
     
     power_off
        returns: VApp object
        throws:
          'CloudError' if power_off_link of VApp is missing
          'VappSuspendedError' if VApp is suspended
          'RestClient::BadRequest' for un-expected errors

     reboot
        returns: vApp object

     reset
        returns: vApp object

     suspend:
        returns: vApp object

     recompose_from_vapp_template
        parameters:
          catalog_name (String): name of catalog
          template_name (String): name of vapp template
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

     vm_exists?
      parameters:
        name (String): name of vm
      returns: boolean
      throws:
        'RestClient::BadRequest' for un-expected errors

     remove_vm_by_name
      parameters:
        name (String): name of vm
       returns: parent VApp object
       throws:
         'ObjectNotFoundError' when VM with the name does not exist
         'CloudError' when VApp is in status of 'POWERED_ON' and can not be recomposed
         'RestClient::BadRequest' for un-expected errors

     list_networks
       returns: array of network names
       throws:
         'RestClient::BadRequest' for un-expected errors

     add_network_by_name
       parameters:
         network_name (String): name of network in vdc org to add to vapp
         vapp_net_name (String, optional): what to name the network of the vapp.
         Default to network_name
         fence_mode (String, optional): Fencing allows identical virtual machines in different
         vApps to be powered on without conflict by isolating the MAC and IP addresses of the
         virtual machines. Available options are "bridged", "isolated" and "natRouted". Default
         to "bridged".
       returns: VApp object
       throws:
        'CloudError' when invalid fence mode is specified
        'ObjectNotFoundError' when network with the name does not exist
        'RestClient::BadRequest' for un-expected errors

     delete_network_by_name
       parameters:
         name (String): name of network to delete
       returns: VApp object
       throws:
         'ObjectNotFoundError' when network with the name does not exist
         'RestClient::BadRequest' for un-expected errors

     create_snapshot
        parameters: 
          snapshot_hash (Hash): hash with :name and :description
        returns: nil
        throws:

     remove_snapshot        
        returns: nil
        throws:

     revert_snapshot        
        returns: nil
        throws:

  VM
  ---

     id
       returns: VM's id

     status
        returns: VM's status

     href
       returns: VM's href

     vcpu:
       returns: number of virtual cpus of VM
       throws:
         'CloudError' when information of number of virtual cpus of VM is unavailable
         'RestClient::BadRequest' for un-expected errors

     vcpu=
       parameters:
         The virtual cpu count.
       returns: VM object
       throws:
         'CloudError' when the cpu count is less than or equal to 0
         'RestClient::BadRequest' for un-expected errors

     memory
       returns: integer number, the size of memory in megabyte
       throws:
         'ApiError' when AllocationUnits of memory is in unexpected form
         'CloudError' when size of memory is zero
         'RestClient::BadRequest' for un-expected errors

     memory=
        parameters:
          The size of memory in megabyte.
        returns: VM object
        throws:
          'CloudError' when the memory size is less than or equal to 0
          'RestClient::BadRequest' for un-expected errors

    ip_address
        returns: The IP address(es) of the VM

    nics
      returns: array of NIC objects
      throws:
        'RestClient::BadRequest' for un-expected errors

     independent_disks
       returns: array of disk objects
       throws:
         'RestClient::BadRequest' for un-expected errors

     list_disks
       returns: names of disks on vm (in parentheses it shows the name of independent disk)
       throws:
         'RestClient::BadRequest' for un-expected errors

     attach_disk
       parameters:
         disk: The disk object.
       returns: VM object
       throws:
         'CloudError' if disk is already attached
         'RestClient::BadRequest' for un-expected errors

     detach_disk
       parameters:
         disk: The disk object.
       returns: VM object
       throws:
         'VmSuspendedError' if containing vApp is suspended
         'CloudError' if disk is not attached or attached to other VM
         'RestClient::BadRequest' for un-expected errors

     power_on
       returns: VM object
       throws:
         'CloudError' if power_on_link of VM is missing
         'RestClient::BadRequest' for un-expected errors

     power_off
       returns: VM object
       throws:
         'CloudError' if power_off_link of VM is missing
         'VmSuspendedError' if VM is suspended
         'RestClient::BadRequest' for un-expected errors

     reboot
        returns: VM object

     reset
        returns: VM object
      
     suspend:
        returns: VM object

     undeploy:

     insert_media
       parameters:
         catalog_name (String): name of catalog
         media_file_name (String): name of media file
       returns: VM object
       throws:
         'ObjectNotFoundError' if when catalog with the name does not exist
         'ObjectNotFoundError' if when media with the name does not exist
         'RestClient::BadRequest' for un-expected errors

     eject_media
       parameters:
         catalog_name (String): name of catalog
         media_file_name (String): name of media file
       returns: VM object
       throws:
         'ObjectNotFoundError' if when catalog with the name does not exist
         'ObjectNotFoundError' if when media with the name does not exist
         'RestClient::BadRequest' for un-expected errors

     add_nic
        parameters:
          network_name (String): name of network to add NIC
          ip_addressing_mode (String, optional): available options are "NONE", "MANUAL",
          "POOL" and "DHCP". Default to "POOL"
          ip (String, optional): IP address for "MANUAL" IP Mode
        return: VM object
        throws:
          'CloudError' if when ip_addressing_mode is invalid
          'CloudError' if ip is not specified in "MANUAL" ip_addressing_mode
          'CloudError' if vm is powered on
          'ObjectNotFoundError' if network is not added to VM's parent VApp
          'RestClient::BadRequest' for un-expected errors

    delete_nics
       parameters:
         nics (splat NIC objects): NICs to delete
       return: VM object
       throws:
         'CloudError' if vm is powered on
         'ObjectNotFoundError' if specified nic index does not exist
         'RestClient::BadRequest' for un-expected errors

    install_vmtools
        returns: nil

     product_section_properties
        returns:
          array of hash values representing properties of product section of VM
          empty array if VM does not have product section
        throws:
          'RestClient::BadRequest' for un-expected errors

     product_section_properties=
        parameters:
          properties (array of hash values): properties of product section of VM
        returns: VM object
        throws:
          'RestClient::BadRequest' for un-expected errors
        note:
          Rebooting VM is needed to reflect product section changes

     internal_disks
       returns: array of internal disk objects
       throws:
         'RestClient::BadRequest' for un-expected errors

     create_internal_disk
       parameters:
         capcity (Integer): disk size in megabyte
         bus_type (String, optional): bus type of disk, defaults to "scsi"
         bus_sub_type (String, optional): bus sub type of disk, defaults to "lsilogic"
       returns: VM object
       throws:
         'CloudError' when capcity is less than or equal to 0
         'CloudError' when bus_type is invalid
         'CloudError' when bus_sub_type is invalid
         'RestClient::BadRequest' for un-expected errors

     delete_internal_disk_by_name
       parameters:
         name (String): name of disk
       returns: VM object
       throws:
         'ObjectNotFoundError' if no disk matching the given name
         'RestClient::BadRequest' for un-expected errors

  VdcStorageProfile
  -----------------
  
     available_storage
       returns:
         integer number of available storage in MB, i.e. storageLimitMB - storageUsedMB
         -1 if 'storageLimitMB' is 0

  EdgeGateway
  -----------

     public_ips:
       returns: IpRanges object
       throws:
         'RestClient::BadRequest' for un-expected errors


## Example
==========
  VCloud_SDK is straightforward to use. Here is an example of creating vApp from vApp template.
  
    1. Create vCloud client object
        
       client = VCloudSdk::Client.new(url, username, password)

       Note that the parameter 'username' should be the VDC user_name@organization_name. For example,
	   the VDC user name is admin, the organization name is myorg, then the 'username' parameter 
       here should be admin@myorg. 
	    
    2. Find the catalog where the vapp template is stored
       catalog = client.find_catalog_by_name(catalog_name)

    3. Create vApp from that vapp template
	   vapp = catalog.instantiate_vapp_template(vapp_template_name, vdc_name, vapp_name)
       
