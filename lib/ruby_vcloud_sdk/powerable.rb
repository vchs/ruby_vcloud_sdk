module VCloudSdk
  
  ###############################################################################################
  # This module defines the shared functions by classes VM and VApp
  # We can retrieve the status, power on, power off, reboots, resets and suspend any VM or VApp 
  ###############################################################################################
  module Powerable

    #############################################################################################
    # Returns the status of the vApp or VM
    # @return [String]  The vApp or VM status:
    #                   - FAILED_CREATION.
    #                   - UNRESOLVED.
    #                   - RESOLVED.
    #                   - SUSPENDED.
    #                   - POWERED_ON.
    #                   - WAITING_FOR_INPUT.    
    #                   - UNKNOWN.
    #                   - UNRECOGNIZED.
    #                   - POWERED_OFF.
    #                   - other.
    #############################################################################################
    def status
      status_code = entity_xml[:status].to_i
      Xml::RESOURCE_ENTITY_STATUS.each_pair do |k, v|        
        return k.to_s if v == status_code
      end

      fail CloudError,
           "Fail to find corresponding status for code '#{status_code}'"
    end

    #############################################################################################
    # Power on vApp or VM 
    # @return [vApp] or [VM] Returns the object
    #############################################################################################
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
      task = connection.post(power_on_link.href, nil)
      task = monitor_task task, @session.time_limit[:power_on]
      Config.logger.info "#{class_name} #{target.name} is powered on."
      self
    end

    #############################################################################################
    # Power off vApp or VM 
    # @return [vApp] or [VM] Returns the object
    #############################################################################################
    def power_off
      target = entity_xml
      class_name = self.class.name.split("::").last
      Config.logger.debug "#{class_name} status: #{target[:status]}"
      if is_status?(target, :SUSPENDED)
        error_msg = "#{class_name} #{target.name} suspended, discard state before powering off."
        fail class_name == "VApp" ? VappSuspendedError : VmSuspendedError,
             error_msg
      end
      if is_status?(target, :POWERED_OFF)
        Config.logger.info "#{class_name} #{target.name} is already powered off."
        return
      end

      power_off_link = target.power_off_link
      unless power_off_link
        fail CloudError, "#{class_name} #{target.name} is not in a state that could be powered off."
      end

      task = connection.post(power_off_link.href, nil)
      monitor_task task, @session.time_limit[:power_off]
      Config.logger.info "#{class_name} #{target.name} is powered off."

      undeploy(target, class_name)
      self
    end

    #############################################################################################
    # Shutdown the GuestOS of vApp or VM
    # Depending the version of vmtools installed on VM it could fail. Version 9227 on Windows KO
    # @return [vApp] or [VM] Returns the object
    #############################################################################################
    def shutdown
      target = entity_xml
      class_name = self.class.name.split("::").last  

      Config.logger.debug "#{class_name} status: #{target[:status]}"
      if is_status?(target, :SUSPENDED)
        error_msg = "#{class_name} #{target.name} suspended, discard state before powering off."
        fail class_name == "VApp" ? VappSuspendedError : VmSuspendedError,
             error_msg
      end
      if is_status?(target, :POWERED_OFF)
        Config.logger.info "#{class_name} #{target.name} is already powered off."
        return
      end

      shutdown_link = target.shutdown_link
      unless shutdown_link
        fail CloudError, "#{class_name} #{target.name} is not in a state that could be powered off."
      end

      task = connection.post(shutdown_link.href, nil)
      monitor_task task, @session.time_limit[:power_off]
      Config.logger.info "#{class_name} #{target.name} is powered off."

      undeploy(target, class_name)
      self

    end

    #############################################################################################
    # Reboots vApp or VM 
    # @return [vApp] or [VM] Returns the object
    #############################################################################################
    def reboot
      target = entity_xml
      class_name = self.class.name.split("::").last
      Config.logger.debug "#{class_name} status: #{target[:status]}"
      if !is_status?(target, :POWERED_ON)
        Config.logger.info "#{class_name} #{target.name} must be powered-on."
        return
      end

      reboot_link = target.reboot_link
        
      Config.logger.info "Rebooting #{class_name} #{target.name}."
      task = connection.post(reboot_link.href, nil)
      task = monitor_task task, @session.time_limit[:power_on]
      Config.logger.info "#{class_name} #{target.name} is rebooted."
      self

    end

    #############################################################################################
    # Resets vApp or VM 
    # @return [vApp] or [VM] Returns the object
    #############################################################################################
    def reset
      target = entity_xml
      class_name = self.class.name.split("::").last
      Config.logger.debug "#{class_name} status: #{target[:status]}"
      if !is_status?(target, :POWERED_ON)
        Config.logger.info "#{class_name} #{target.name} must be powered-on."
        return
      end

      reset_link = target.reset_link      
      
      Config.logger.info "Reseting #{class_name} #{target.name}."
      task = connection.post(reset_link.href, nil)
      task = monitor_task task, @session.time_limit[:power_on]
      Config.logger.info "#{class_name} #{target.name} is reseted."
      self
    end

    #############################################################################################
    # Suspends vApp or VM 
    # @return [vApp] or [VM] Returns the object
    #############################################################################################
    def suspend
      target = entity_xml
      class_name = self.class.name.split("::").last
      Config.logger.debug "#{class_name} status: #{target[:status]}"      
      if !is_status?(target, :POWERED_ON)
        Config.logger.info "#{class_name} #{target.name} must be powered-on."
        return
      end

      suspend_link = target.suspend_link      
      
      Config.logger.info "Suspending #{class_name} #{target.name}."
      task = connection.post(suspend_link.href, nil)
      task = monitor_task task, @session.time_limit[:power_on]
      Config.logger.info "#{class_name} #{target.name} is suspended."

      undeploy(target, class_name)
      self
    end

    private

    def is_status?(target, status)
      target[:status] == Xml::RESOURCE_ENTITY_STATUS[status].to_s
    end

    def undeploy(target, class_name)
      params = Xml::WrapperFactory.create_instance("UndeployVAppParams")
      # Even for VM it's called UndeployVappParams
      task = connection.post(target.undeploy_link.href, params)
      task = monitor_task(task, @session.time_limit[:undeploy])
      Config.logger.info "#{class_name} #{target.name} is undeployed."
      task
    end
  end
  ###############################################################################################
end
