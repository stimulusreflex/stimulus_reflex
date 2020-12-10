# frozen_string_literal: true

module StimulusReflex
  class CableReadyChannels
    stimulus_reflex_channel_methods = CableReady::Channels.instance.operations.keys + [:broadcast, :broadcast_to]
    delegate(*stimulus_reflex_channel_methods, to: "stimulus_reflex_channel")
    delegate :[], to: "cable_ready_channels"

    def initialize(stream_name)
      @stream_name = stream_name
    end

    def cable_ready_channels
      CableReady::Channels.instance
    end

    def stimulus_reflex_channel
      CableReady::Channels.instance[@stream_name]
    end
  end
end
