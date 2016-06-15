module VCloudSdk

  class Resources
    attr_reader :cpu_available, :cpu_limit,  :memory_available, :memory_limit

    def initialize(cpu,memory)
      @cpu_available = cpu.available_cores
      @cpu_limit = cpu.limit_cores
      @memory_available = memory.available_mb
      @memory_limit = memory.limit_mb
    end

  end
end
