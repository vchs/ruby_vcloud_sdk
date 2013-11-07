module VCloudSdk

  class Memory
    attr_reader :available_mb

    def initialize(available_mb)
      @available_mb = available_mb
    end
  end

end
