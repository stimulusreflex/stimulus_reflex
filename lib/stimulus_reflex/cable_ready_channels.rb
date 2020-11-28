module StimulusReflex
  class CableReadyChannels
    def initialize(stream_name)
      @cable_ready_channels = CableReady::Channels.instance
      @stimulus_reflex_channel = @cable_ready_channels[stream_name]
    end

    def method_missing(name, *args)
      return @stimulus_reflex_channel.send(name, *args) if @stimulus_reflex_channel.respond_to?(name)
      @cable_ready_channels.send(name, *args)
    end

    def respond_to_missing?(name, include_all)
      @stimulus_reflex_channel.respond_to?(name, include_all) ||
        @cable_ready_channels.respond_to?(name, include_all)
    end
  end
end
