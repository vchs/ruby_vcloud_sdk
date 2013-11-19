module VCloudSdk
  class Config
    class << self
      attr_accessor :logger

      def configure(config)
        @logger = config[:logger] || @logger || Logger.new(STDOUT)
      end
    end
  end
end
