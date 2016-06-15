module VCloudSdk

  class Memory
    attr_reader :available_mb, :limit_mb

    def initialize(available_mb,limit_mb)
      @available_mb = available_mb
      @limit_mb = limit_mb      
    end
  end

end
