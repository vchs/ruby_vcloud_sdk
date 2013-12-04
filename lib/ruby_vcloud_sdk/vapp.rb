require_relative "infrastructure"
require_relative "vm"
require "securerandom"

module VCloudSdk
  class VApp
    include Infrastructure

    attr_reader :name

    def initialize(session, vapp_link)
      @session = session
      @vapp_link = vapp_link
      @name = @vapp_link.name
    end

    def delete
      vapp = connection.get(@vapp_link)

      if is_vapp_status?(vapp, :POWERED_ON)
        fail CloudError,
             "vApp #{name} is powered on, power-off before deleting."
      end

      unless vapp.running_tasks.empty?
        Config.logger.info "vApp #{name} has tasks in progress, wait until done."
        vapp.running_tasks.each do |task|
          monitor_task(task)
        end
      end

      Config.logger.info "Deleting vApp #{name}."
      monitor_task(connection.delete(vapp.remove_link),
                   @session.time_limit[:delete_vapp]) do |task|
        Config.logger.info "vApp #{name} deleted."
        return task
      end

      fail ApiRequestError,
           "Fail to delete vApp #{name}"
    end

    def power_on
      vapp = connection.get(@vapp_link)
      Config.logger.debug "vApp status: #{vapp[:status]}"
      if is_vapp_status?(vapp, :POWERED_ON)
        Config.logger.info "vApp #{name} is already powered-on."
        return
      end

      power_on_link = vapp.power_on_link
      unless power_on_link
        fail CloudError,
             "vApp #{name} not in a state to be powered on."
      end

      Config.logger.info "Powering on vApp #{name}."
      task = connection.post(power_on_link, nil)
      task = monitor_task task, @session.time_limit[:power_on]
      Config.logger.info "vApp #{name} is powered on."
      task
    end

    def power_off
      vapp = connection.get(@vapp_link)
      Config.logger.debug "vApp status: #{vapp[:status]}"
      if is_vapp_status?(vapp, :SUSPENDED)
        Config.logger.info "vApp #{name} suspended, discard state before powering off."
        fail VappSuspendedError, "discard state first"
      end

      if is_vapp_status?(vapp, :POWERED_OFF)
        Config.logger.info "vApp #{name} is already powered off."
        return
      end

      power_off_link = vapp.power_off_link
      unless vapp.power_off_link
        fail CloudError, "vApp #{name} is not in a state that could be powered off."
      end

      task = connection.post(power_off_link, nil)
      monitor_task task, @session.time_limit[:power_off]
      Config.logger.info "vApp #{name} is in powered off state. Need to be undeployed."

      undeploy_vapp(vapp)
    end

    def recompose_from_vapp_template(catalog_name, template_name)
      recompose_vapp_link = connection
                              .get(@vapp_link)
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

      task = connection.post recompose_vapp_link,
                             recompose_from_vapp_template_param(template)

      monitor_task task, @session.time_limit[:recompose_vapp]
      Config.logger.info "vApp #{name} is recomposed."
      self
    end

    def vms
      vapp = connection.get(@vapp_link)
      vapp.vms.map do |vm|
        VCloudSdk::VM.new(@session, vm.href)
      end
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
      vapp = connection.get(@vapp_link)
      vapp_status_code = vapp[:status].to_i
      Xml::RESOURCE_ENTITY_STATUS.each_pair do |k,v|
        if v == vapp_status_code
          return k.to_s
        end
      end

      fail CloudError,
           "Fail to find corresponding status for code '#{vapp_status_code}'"
    end

    def recompose_from_vapp_template_param(template)
      params = Xml::WrapperFactory.create_instance "RecomposeVAppParams"
      params.name = name
      params.all_eulas_accepted = true
      params.add_source_item template.href
      params
    end
  end
end
