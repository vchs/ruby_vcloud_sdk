module VCloudSdk

  ###############################################################################################
  # This module defines the shared functions by classes such as Client, Catalog and VDC
  # Make sure instance variable @session is available 
  ###############################################################################################
  module Infrastructure
    ERROR_STATUSES = [Xml::TASK_STATUS[:ABORTED], Xml::TASK_STATUS[:ERROR],
                      Xml::TASK_STATUS[:CANCELED]]
    SUCCESS_STATUS = [Xml::TASK_STATUS[:SUCCESS]]

    private

    #############################################################################################
    # Returns the Virtual Data Center identified by name. 
    # @return         [VDC]  The VDC.
    #############################################################################################
    def find_vdc_by_name(name)
      vdc_link = @session.org.vdc_link(name)
      fail ObjectNotFoundError, "VDC #{name} not found" unless vdc_link
      VCloudSdk::VDC.new(@session, vdc_link)
    end

    #############################################################################################
    # Obtain if the VDC identified by name exists.
    # @return         [Boolean]  If the VDC identified by name exists, returns "True".
    #############################################################################################
    def vdc_exists?(name)
      @session.org.vdcs.any? do |vdc|
        vdc.name == name
      end
    end

    #############################################################################################
    # Returns the list of VDC existing.
    # @return         [VDC]  The array of VDC.
    #############################################################################################
    def vdcs
       #@session.org.vdcs
        @session.org.vdcs.map do |vdc_link|
        VCloudSdk::VDC.new(@session, vdc_link)
      end

    end

    #############################################################################################
    # Returns the Network identified by name. 
    # @return         [Network]  The network returned.
    #############################################################################################
    def find_network_by_name(name)
      @session.org.networks.each do |network_link|
        if network_link.name == name
          return VCloudSdk::Network.new(@session, network_link)
        end
      end

      fail ObjectNotFoundError, "Network '#{name}' is not found"
    end

    #############################################################################################
    # Obtain if the network identified by name exists.
    # @return         [Boolean]  If the network identified by name exists, returns "True".
    #############################################################################################
    def network_exists?(name)
      @session.org.networks.any? do |network|
        network.name == name
      end
    end

    #############################################################################################
    # Returns the list of catalogs.
    # @return         [Catalog]  The array of existing catalogs.
    #############################################################################################
    def catalogs
      @session.org.catalogs.map do |catalog_link|
        VCloudSdk::Catalog.new(@session, catalog_link)
      end
    end

    #############################################################################################
    # Returns the name's list of Networks created in the Virtual Data Center. 
    # @return         [String]  The array of Network's names.
    #############################################################################################
    def list_catalogs
      @session.org.catalogs.map do |catalog_link|
        catalog_link.name
      end
    end

    #############################################################################################
    # Obtain if the catalog identified by name exists.
    # @return         [Boolean]  If the catalog identified by name exists, returns "True".
    #############################################################################################
    def catalog_exists?(name)
      @session.org.catalogs.any? do |catalog|
        catalog.name == name
      end
    end

    #############################################################################################
    # Returns the catalog identified by name. 
    # @return         [Catalog]  The catalog returned.
    #############################################################################################
    def find_catalog_by_name(name)
      @session.org.catalogs.each do |catalog_link|
        if catalog_link.name == name
          return VCloudSdk::Catalog.new(@session, catalog_link)
        end
      end

      fail ObjectNotFoundError, "Catalog '#{name}' is not found"
    end

    #############################################################################################
    # Returns the object's connection. 
    # @return         [Connection]  The connection returned.
    #############################################################################################
    def connection
      @session.connection
    end

    #############################################################################################
    # Monitores the task passed as a argument.
    #############################################################################################
    def monitor_task(
      task,
      time_limit = @session.time_limit[:default],
      error_statuses = ERROR_STATUSES,
      success = SUCCESS_STATUS,
      delay = @session.delay,
      &b)

      iterations = time_limit / delay
      i = 0
      prev_progress = task.progress
      prev_status = task.status
      current_task = task
      while i < iterations
        Config.logger.debug %Q{
          #{current_task.urn} #{current_task.operation} is #{current_task.status}
        }

        if task_is_success(current_task, success)
          if b
            return b.call(current_task)
          else
            return current_task
          end
        elsif task_has_error(current_task, error_statuses)
          fail ApiRequestError,
               "Task #{task.urn} #{task.operation} did not complete successfully."
        elsif task_progressed?(current_task, prev_progress, prev_status)
          Config.logger.debug %Q{
            task status #{prev_status} =>
            #{current_task.status}, progress #{prev_progress}% =>
            #{current_task.progress}%, timer #{i} reset.
          }
          prev_progress = current_task.progress
          prev_status = current_task.status
          i = 0  # Reset clock if status changes or running task makes progress
          sleep(delay)
        else
          Config.logger.debug %Q{
            Approximately #{i * delay}s elapsed waiting for #{current_task.operation} to
            reach #{success.join("/")}/#{error_statuses.join("/")}.
            Checking again in #{delay} seconds.
          }
          if current_task.progress
            Config.logger.debug(
              "Task #{task.urn} progress: #{current_task.progress} %.")
          end
          sleep(delay)
        end
        current_task = connection.get(task)
        i += 1
      end
      fail ApiTimeoutError,
           "Task #{task.operation} did not complete within limit of #{time_limit} seconds."
    end

    #############################################################################################
    # Obtain if the task has progressed or not.
    # @return         [Boolean]  If the task has progressed, returns "True".
    #############################################################################################
    def task_progressed?(current_task, prev_progress, prev_status)
      (current_task.progress && (current_task.progress != prev_progress)) ||
        (current_task.status && (current_task.status != prev_status))
    end

    #############################################################################################
    # Obtain if the task has succeeded or not.
    # @return         [Boolean]  If the task has succeeded, returns "True".
    #############################################################################################
    def task_is_success(current_task, success = SUCCESS_STATUS)
      success.find do |s|
        s.downcase == current_task.status.downcase
      end
    end

    #############################################################################################
    # Obtain if the task has an error or not.
    # @return         [Boolean]  If the task has an error, returns "True".
    #############################################################################################
    def task_has_error(current_task, error_statuses = ERROR_STATUSES)
      error_statuses.find do |s|
        s.downcase == current_task.status.downcase
      end
    end

    #############################################################################################
    # Returns the object's XML representation. 
    # @return         [String]  The XML representation of the object.
    #############################################################################################
    def entity_xml
      connection.get(@link)
    end

    def wait_for_running_tasks(subject, subject_display)
      unless subject.running_tasks.empty?
        Config.logger.info "#{subject_display} has tasks in progress, wait until done."
        subject.running_tasks.each do |task|
          monitor_task(task)
        end
      end
    end
  end
  ###############################################################################################
end
