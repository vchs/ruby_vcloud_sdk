module VCloudSdk

  class CPU
    attr_reader :available_cores

    def initialize(available_cores)
      @available_cores = available_cores
    end
  end

end
