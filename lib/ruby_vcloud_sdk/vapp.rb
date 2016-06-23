require_relative "infrastructure"
require_relative "powerable"
require_relative "vm"
require_relative "network_config"

module VCloudSdk

  ######################################################################################
  # This class represents a vApp of the Virtual Data Center.
  ######################################################################################
  class VApp
    include Infrastructure
    include Powerable

    ####################################################################################
    # Initializes a vApp object associated with a vCloud Session and the vApp's link. 
    # @param session   [Session] The client's session
    # @param link      [String]  The vCloud link of the vApp
    ####################################################################################
    def initialize(session, link)
      @session = session
      @link = link
    end

    ####################################################################################
    # Returns the identifier of the vApp (uuid) 
    # @return      [String]  The identifier of the vApp
    ####################################################################################
    def id      
      id = entity_xml.urn
      id.split(":")[3]     
    end

    ####################################################################################
    # Returns the name of the vApp 
    # @return      [String]  The name of the vApp
    ####################################################################################
    def name
      entity_xml.name
    end

    ####################################################################################
    # Deletes the vApp in the VDC.
    # To delete the vApp, it must be on power off state. 
    ####################################################################################
    def delete
      vapp = entity_xml
      vapp_name = name

      if is_status?(vapp, :POWERED_ON)
        fail CloudError,
             "vApp #{vapp_name} is powered on, power-off before deleting."
      end

      wait_for_running_tasks(vapp, "VApp #{vapp_name}")

      Config.logger.info "Deleting vApp #{vapp_name}."
      monitor_task(connection.delete(vapp.remove_link.href),
                   @session.time_limit[:delete_vapp]) do |task|
        Config.logger.info "vApp #{vapp_name} deleted."
        return
      end

      fail ApiRequestError,
           "Fail to delete vApp #{vapp_name}"
    end

    ####################################################################################
    # Recompose the vApp with a vApp template 
    # @param  catalog_name  [String]  The name of Catalog
    # @param  template_name [String]  The name of vApp Template
    # @return               [VApp]    The recomposed vApp
    ####################################################################################
    def recompose_from_vapp_template(catalog_name, template_name)
      recompose_vapp_link = get_recompose_vapp_link

      Config.logger.info "Recomposing from template '#{template_name}' in catalog 
                          '#{catalog_name}'."
      catalog = find_catalog_by_name catalog_name

      template = catalog.find_vapp_template_by_name template_name

      task = connection.post recompose_vapp_link.href,
                             recompose_from_vapp_template_param(template)

      monitor_task task, @session.time_limit[:recompose_vapp]
      Config.logger.info "vApp #{name} is recomposed."
      self
    end

    ####################################################################################
    # Returns array of Vm objects associated with vApp
    # @return [VApp] an array of vApp
    ####################################################################################
    def vms
      entity_xml.vms.map do |vm|
        VCloudSdk::VM.new(@session, vm.href)
      end
    end

    ####################################################################################
    # Returns array with the names of the Vms associated with vApp
    # @return [String] an array of VM's names
    ####################################################################################
    def list_vms
      entity_xml.vms.map do |vm|
        vm.name
      end
    end

    ####################################################################################
    # Returns if the VM identified by name exists.
    # @return [Boolean] True  => the VM exists.
    #                   False => otherwise.
    ####################################################################################
    def vm_exists?(name)
      entity_xml.vms.any? do |vm|
        vm.name == name
      end
    end

    ####################################################################################
    # Returns the VM identified by name.
    # @return [Vm] The VM identified by name, if it exists.
    ####################################################################################
    def find_vm_by_name(name)
      entity_xml.vms.each do |vm|
        return VCloudSdk::VM.new(@session, vm.href) if vm.name == name
      end

      fail ObjectNotFoundError, "VM '#{name}' is not found"
    end

    ####################################################################################
    # Deletes the VM identified by name.
    # @return [Vm] The VM deleted.
    ####################################################################################
    def remove_vm_by_name(vm_name)
      target_vm = find_vm_by_name vm_name
      recompose_vapp_link = get_recompose_vapp_link

      task = connection.post recompose_vapp_link.href,
                             remove_vm_param(target_vm)

      monitor_task task, @session.time_limit[:recompose_vapp]
      Config.logger.info "VM #{vm_name} is removed."
      self
    end

    ####################################################################################
    # Returns the names of networks asociated with the vApp.
    # @return [String] an array of network's names
    ####################################################################################
    def list_networks
      entity_xml
        .network_config_section
        .network_configs
        .map { |network_config| network_config.network_name }
    end

    ####################################################################################
    # Adds a network to the vApp.
    # @param  network_name  [String]  The name of network in vdc org to add to vapp.
    # @param  vapp_net_name [String]  Optional. What to name the network of the vapp.
    #                                 Default to network_name
    # @param  fence_mode    [String]  Optional. Fencing allows identical virtual 
    #                                 machines in different vApps to be powered on 
    #                                 without conflict by isolating the MAC and IP 
    #                                 addresses of the virtual machines. Available 
    #                                 options are "BRIDGED","ISOLATED" and "NAT_ROUTED" 
    #                                 Default to "BRIDGED".    
    # @return               [VApp]    The vApp
    ####################################################################################
    def add_network_by_name(
        network_name,
        vapp_net_name = nil,
        fence_mode = Xml::FENCE_MODES[:BRIDGED])
      fail CloudError,
           "Invalid fence mode '#{fence_mode}'" unless Xml::FENCE_MODES
                                                         .each_value
                                                         .any? { |m| m == fence_mode }
      network = find_network_by_name(network_name)
      new_vapp_net_name = vapp_net_name.nil? ? network.name : vapp_net_name
      network_config_param = network_config_param(
                               network,
                               new_vapp_net_name,
                               fence_mode)
      payload = entity_xml.network_config_section
      payload.add_network_config(network_config_param)
      task = connection.put(payload.href,
                            payload,
                            Xml::MEDIA_TYPE[:NETWORK_CONFIG_SECTION])
      monitor_task(task)
      self
    end

    ####################################################################################
    # Deletes the network identified with name.
    # To delete the network, it cannot be used by any VM's.
    # @return [VApp] The vApp.
    ####################################################################################
    def delete_network_by_name(name)
      unless list_networks.any? { |network_name| network_name == name }
        fail ObjectNotFoundError,
             "Network '#{name}' is not found"
      end

      fail CloudError,
           %Q{
               Network '#{name}' is being used by one or more VMs.
               Please remove the NIC(s) in VM(s) that are in use of the network.
               Check logs for details.
             } if network_in_use?(name)

      payload = entity_xml.network_config_section
      payload.delete_network_config(name)
      task = connection.put(payload.href,
                            payload,
                            Xml::MEDIA_TYPE[:NETWORK_CONFIG_SECTION])
      monitor_task(task)
      self
    end

    ####################################################################################
    # Creates a snapshot of the vApp.
    # @param snapshot_name  [String] Optional.The name of the snapshot
    ####################################################################################
    def create_snapshot(snapshot_name)
      new_snapshot_name = snapshot_name.nil? ? "#{name} Snapshot" : snapshot_name    
      options = {
        :name => new_snapshot_name,
        :description => "Snapshot of vApp #{name}"
      }
      target = entity_xml          
      create_snapshot_link = target.create_snapshot_link      
      params = Xml::WrapperFactory.create_instance("CreateSnapshotParams")

      Config.logger.info "Creating a snapshot on vApp #{name}."      
      task = connection.post(target.create_snapshot_link.href,params)      
      monitor_task(task)
      Config.logger.error "vApp #{name} has created a snapshot"
    end

    ####################################################################################
    # Deletes ALL the snapshots of the vApp.
    ####################################################################################
    def remove_snapshot
      target = entity_xml
      remove_snapshot_link = target.remove_snapshot_link

      Config.logger.info "Removing all snapshots on vApp #{name}."
      task = connection.post(target.remove_snapshot_link.href,nil)
      monitor_task(task)
      Config.logger.error "vApp #{name} has removed all snapshots"
    end

    ####################################################################################
    # Revert the LAST snapshot created in the vApp.
    ####################################################################################
    def revert_snapshot
      target = entity_xml
      revert_snapshot_link = target.revert_snapshot_link
      
      Config.logger.info "Reverting to current snapshot on vApp #{name}."
      task = connection.post(target.revert_snapshot_link.href,nil)
      monitor_task(task)
      Config.logger.error "vApp #{name} has reverted a snapshot"
    end

    private

    def recompose_from_vapp_template_param(template)
      Xml::WrapperFactory.create_instance("RecomposeVAppParams").tap do |params|
        params.name = name
        params.all_eulas_accepted = true
        params.add_source_item template.href
      end
    end

    def get_recompose_vapp_link
      recompose_vapp_link = connection
                              .get(@link)
                              .recompose_vapp_link

      if recompose_vapp_link.nil?
        # We are able to recompose vapp when it is suspended or powered off
        # If vapp is powered on, throw exception
        fail CloudError,
             "VApp is in status of '#{status}' and can not be recomposed"
      end

      recompose_vapp_link
    end

    def remove_vm_param(vm)
      Xml::WrapperFactory.create_instance("RecomposeVAppParams").tap do |params|
        params.name = name
        params.all_eulas_accepted = true
        params.add_delete_item vm.href
      end
    end

    def network_config_param(
        network,
        vapp_net_name,
        fence_mode)      
      Xml::WrapperFactory.create_instance("NetworkConfig").tap do |params|
        network_entity_xml = connection.get(network.href)
        params.ip_scope.tap do |ip_scope|
          net_ip_scope = network_entity_xml.ip_scope
          ip_scope.is_inherited = net_ip_scope.is_inherited?
          ip_scope.gateway = net_ip_scope.gateway
          ip_scope.netmask = net_ip_scope.netmask   
          ip_scope.ip_ranges.add_ranges(net_ip_scope.ip_ranges.ranges) if !net_ip_scope.ip_ranges.nil?  ##per poder afegir xarxes amb DHCP que no tenen POOL IP STATIC                
        end
        params.fence_mode = fence_mode
        params.parent_network["name"] = network_entity_xml["name"]
        params.parent_network["href"] = network_entity_xml["href"]
        params["networkName"] = vapp_net_name
      end
    end

    def network_in_use?(network_name)
      network_in_use = false
      vms.each do |vm|
        vm.list_networks.each do |net_name|
          if net_name == network_name
            network_in_use = true
            Config.logger.error "VM #{vm.name} is using network #{network_name}"
          end
        end
      end

      network_in_use
    end
  end
end
