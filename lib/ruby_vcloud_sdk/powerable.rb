module VCloudSdk
  # Shared functions by classes VM and VApp
  module Powerable
    def status
      status_code = entity_xml[:status].to_i
      Xml::RESOURCE_ENTITY_STATUS.each_pair do |k, v|
        return k.to_s if v == status_code
      end

      fail CloudError,
           "Fail to find corresponding status for code '#{status_code}'"
    end

    # Power on VApp or VM
    def power_on
      target = entity_xml
      class_name = self.class.name.split("::").last
      Config.logger.debug "#{class_name} status: #{target[:status]}"
      if is_status?(target, :POWERED_ON)
        Config.logger.info "#{class_name} #{target.name} is already powered-on."
        return
      end

      power_on_link = target.power_on_link
      unless power_on_link
        fail CloudError,
             "#{class_name} #{target.name} not in a state able to power on."
      end

      Config.logger.info "Powering on #{class_name} #{target.name}."
      task = connection.post(power_on_link, nil)
      task = monitor_task task, @session.time_limit[:power_on]
      Config.logger.info "#{class_name} #{target.name} is powered on."
      task
    end

    private

    def is_status?(target, status)
      target[:status] == Xml::RESOURCE_ENTITY_STATUS[status].to_s
    end
  end
end
