module VCloudSdk

  ################################################################################
  # This class represents the Memory resource of the Virtual Data Center.
  ################################################################################
  class Memory
    attr_reader :available_mb, :limit_mb

  	##############################################################################
    # Initialize a Memory resource of the VDC. 
    # @param available_mb    [String] The amount memory not used in the VDC in MB
    # @param limit_mb 	 	 [String] The amount memory to use in the VDC in MB
    ##############################################################################
    def initialize(available_mb,limit_mb)
      @available_mb = available_mb
      @limit_mb = limit_mb      
    end
  end

end
