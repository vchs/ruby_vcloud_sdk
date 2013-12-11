require_relative "infrastructure"
require_relative "vm"

module VCloudSdk
  class VApp
    include Infrastructure

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

      if is_vapp_status?(vapp, :POWERED_ON)
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

    def power_on
      vapp = entity_xml
      vapp_name = vapp.name
      Config.logger.debug "vApp status: #{vapp[:status]}"
      if is_vapp_status?(vapp, :POWERED_ON)
        Config.logger.info "vApp #{vapp_name} is already powered-on."
        return
      end

      power_on_link = vapp.power_on_link
      unless power_on_link
        fail CloudError,
             "vApp #{vapp_name} not in a state to be powered on."
      end

      Config.logger.info "Powering on vApp #{vapp_name}."
      task = connection.post(power_on_link, nil)
      task = monitor_task task, @session.time_limit[:power_on]
      Config.logger.info "vApp #{vapp_name} is powered on."
      task
    end

    def power_off
      vapp = entity_xml
      vapp_name = vapp.name
      Config.logger.debug "vApp status: #{vapp[:status]}"
      if is_vapp_status?(vapp, :SUSPENDED)
        Config.logger.info "vApp #{vapp_name} suspended, discard state before powering off."
        fail VappSuspendedError, "discard state first"
      end

      if is_vapp_status?(vapp, :POWERED_OFF)
        Config.logger.info "vApp #{vapp_name} is already powered off."
        return
      end

      power_off_link = vapp.power_off_link
      unless power_off_link
        fail CloudError, "vApp #{vapp_name} is not in a state that could be powered off."
      end

      task = connection.post(power_off_link, nil)
      monitor_task task, @session.time_limit[:power_off]
      Config.logger.info "vApp #{vapp_name} is in powered off state. Need to be undeployed."

      undeploy_vapp(vapp)
    end

    def recompose_from_vapp_template(catalog_name, template_name)
      recompose_vapp_link = connection
                              .get(@link)
                              .recompose_vapp_link

      if recompose_vapp_link.nil?
        # We are able to recompose vapp when it is suspended or powered off
        # If vapp is powered on, throw exception
        fail CloudError,
             "VApp is in status of '#{status}' and can not be recomposed"
      end

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
        if vm.name == name
          return VCloudSdk::VM.new(@session, vm.href)
        end
      end

      fail ObjectNotFoundError, "VM '#{name}' is not found"
    end

    private

    def undeploy_vapp(vapp)
      params = Xml::WrapperFactory.create_instance("UndeployVAppParams")
      task = connection.post(vapp.undeploy_link, params)
      task = monitor_task(task, @session.time_limit[:undeploy])
      Config.logger.info "vApp #{name} is undeployed."
      task
    end

    def is_vapp_status?(vapp, status)
      vapp[:status] == Xml::RESOURCE_ENTITY_STATUS[status].to_s
    end

    def status
      vapp_status_code = entity_xml[:status].to_i
      Xml::RESOURCE_ENTITY_STATUS.each_pair do |k,v|
        if v == vapp_status_code
          return k.to_s
        end
      end

      fail CloudError,
           "Fail to find corresponding status for code '#{vapp_status_code}'"
    end

    def recompose_from_vapp_template_param(template)
      Xml::WrapperFactory.create_instance("RecomposeVAppParams").tap do |params|
        params.name = name
        params.all_eulas_accepted = true
        params.add_source_item template.href
      end
    end
  end
end
