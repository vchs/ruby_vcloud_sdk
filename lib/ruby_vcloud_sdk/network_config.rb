module VCloudSdk

  class NetworkConfig
    attr_reader :network_name, :vapp_net_name, :fence_mode

    def initialize(
        network_name,
        vapp_net_name = nil,
        fence_mode = Xml::FENCE_MODES[:BRIDGED])
      @network_name = network_name
      @vapp_net_name = vapp_net_name
      @fence_mode = fence_mode
    end
  end

end
