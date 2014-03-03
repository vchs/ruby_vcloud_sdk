require_relative "infrastructure"
require_relative "powerable"
require_relative "vm"

module VCloudSdk
  class VApp
    include Infrastructure
    include Powerable

    def initialize(session, link)
      @session = session
      @link = link
    end

    def name
      entity_xml.name
    end

    def delete
      vapp = entity_xml
      vapp_name = name

      if is_status?(vapp, :POWERED_ON)
        fail CloudError,
             "vApp #{vapp_name} is powered on, power-off before deleting."
      end

      wait_for_running_tasks(vapp, "VApp #{vapp_name}")

      Config.logger.info "Deleting vApp #{vapp_name}."
      monitor_task(connection.delete(vapp.remove_link),
                   @session.time_limit[:delete_vapp]) do |task|
        Config.logger.info "vApp #{vapp_name} deleted."
        return task
      end

      fail ApiRequestError,
           "Fail to delete vApp #{vapp_name}"
    end

    def recompose_from_vapp_template(catalog_name, template_name)
      recompose_vapp_link = get_recompose_vapp_link

      Config.logger.info "Recomposing from template '#{template_name}' in catalog '#{catalog_name}'."
      catalog = find_catalog_by_name catalog_name

      template = catalog.find_vapp_template_by_name template_name

      task = connection.post recompose_vapp_link.href,
                             recompose_from_vapp_template_param(template)

      monitor_task task, @session.time_limit[:recompose_vapp]
      Config.logger.info "vApp #{name} is recomposed."
      self
    end

    def vms
      entity_xml.vms.map do |vm|
        VCloudSdk::VM.new(@session, vm.href)
      end
    end

    def list_vms
      entity_xml.vms.map do |vm|
        vm.name
      end
    end

    def find_vm_by_name(name)
      entity_xml.vms.each do |vm|
        return VCloudSdk::VM.new(@session, vm.href) if vm.name == name
      end

      fail ObjectNotFoundError, "VM '#{name}' is not found"
    end

    def remove_vm_by_name(vm_name)
      target_vm = find_vm_by_name vm_name
      recompose_vapp_link = get_recompose_vapp_link

      task = connection.post recompose_vapp_link.href,
                             remove_vm_param(target_vm)

      monitor_task task, @session.time_limit[:recompose_vapp]
      Config.logger.info "VM #{vm_name} is removed."
      self
    end

    def list_networks
      entity_xml
        .network_config_section
        .network_configs
        .map { |network_config| network_config.network_name }
    end

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
    end

    def delete_network_by_name(name)
      unless list_networks.any? { |network_name| network_name == name}
        fail ObjectNotFoundError,
             "Network '#{name}' is not found"
      end

      network_in_use = false
      vms.each do |vm|
        vm.list_networks.each do |network_name|
          if network_name == name
            network_in_use = true
            Config.logger.error "VM #{vm.name} is in use of network #{name}"
          end
        end
      end

      if network_in_use
        fail CloudError,
             %Q{
               Network '#{name}' is being used by one or more VMs.
               Please remove the NIC(s) in VM(s) that are in use of the network.
               Check logs for details.
             }
      end

      payload = entity_xml.network_config_section
      payload.delete_network_config(name)
      task = connection.put(payload.href,
                            payload,
                            Xml::MEDIA_TYPE[:NETWORK_CONFIG_SECTION])
      monitor_task(task)
      nil
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
          ip_scope.ip_ranges.add_ranges(net_ip_scope.ip_ranges.ranges)
        end
        params.fence_mode = fence_mode
        params.parent_network["name"] = network_entity_xml["name"]
        params.parent_network["href"] = network_entity_xml["href"]
        params["networkName"] = vapp_net_name
      end
    end
  end
end
