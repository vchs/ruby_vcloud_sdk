module VCloudSdk

  ################################################################################
  # This class represents the resource of the Virtual Data Center.
  ################################################################################
  class Resources
    attr_reader :cpu_available, :cpu_limit, :cpu_used 
    attr_reader :memory_available, :memory_limit, :memory_used 
    ##############################################################################
    # Initialize a Resource for the VDC. 
    # @param cpu       [CPU]    The CPU resource of the VDC.
    # @param memory    [Memory] The Memory resource of the VDC.
    ##############################################################################
    def initialize(cpu,memory)
      @cpu_available 	  	= cpu.available_cores
      @cpu_limit 		      = cpu.limit_cores
      @cpu_used 		      = cpu.limit_cores.to_i - cpu.available_cores.to_i

      @memory_available 	= memory.available_mb
      @memory_limit 	  	= memory.limit_mb
      @memory_used 		  	= memory.limit_mb.to_i - memory.available_mb.to_i
    end
  end
end
