module VCloudSdk

  class CPU
    attr_reader :available_cores, :limit_cores

    def initialize(available_cores,limit_cores)
      @available_cores = available_cores
      @limit_cores = limit_cores      
    end
  end

end
