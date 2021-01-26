# frozen_string_literal: true

module StimulusReflex
  class CableReadyChannels
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

    def method_missing(name, *args)
      return stimulus_reflex_channel.public_send(name, *args) if stimulus_reflex_channel.respond_to?(name)
      super
    end

    def respond_to_missing?(name, include_all)
      stimulus_reflex_channel.respond_to?(name) || super
    end
  end
end
