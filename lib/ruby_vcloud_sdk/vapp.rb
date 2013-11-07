require_relative "infrastructure"

module VCloudSdk
  class VApp
    include Infrastructure

    attr_reader :name

    def initialize(session, vapp_xml_obj)
      @session = session
      @vapp_xml_obj = vapp_xml_obj
      @name = @vapp_xml_obj.name
    end

    def delete
      vapp = connection.get(@vapp_xml_obj)

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
      vapp = connection.get(@vapp_xml_obj)
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

    private

    def is_vapp_status?(vapp, status)
      vapp[:status] == Xml::RESOURCE_ENTITY_STATUS[status].to_s
    end
  end
end
