module StimulusReflex
  class CableReadyChannels
    stimulus_reflex_channel_methods = CableReady::Channels.instance.operations.keys + [:broadcast, :broadcast_to]
    delegate(*stimulus_reflex_channel_methods, to: "@stimulus_reflex_channel")
    delegate :[], to: "@cable_ready_channels"

    def initialize(stream_name)
      @cable_ready_channels = CableReady::Channels.instance
      @stimulus_reflex_channel = @cable_ready_channels[stream_name]
    end
  end
end
