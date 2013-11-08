module VCloudSdk

  class Resources
    attr_reader :cpu
    attr_reader :memory

    def initialize(cpu, memory)
      @cpu = cpu
      @memory = memory
    end

  end
end
