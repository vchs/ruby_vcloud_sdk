module VCloudSdk

  ################################################################################
  # This class represents the CPU resource of the Virtual Data Center.
  ################################################################################
  class CPU
    attr_reader :available_cores, :limit_cores

    ##############################################################################
    # Initialize a CPU resource of the VDC. 
    # @param available_cores    [String] The cores not used in the VDC.
    # @param limit_cores	 	[String] The maximum cores to use in the VDC.
    ##############################################################################
    def initialize(available_cores,limit_cores)
      @available_cores = available_cores
      @limit_cores = limit_cores      
    end
  end

end
