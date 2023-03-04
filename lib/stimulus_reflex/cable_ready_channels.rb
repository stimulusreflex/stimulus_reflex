# frozen_string_literal: true

module StimulusReflex
  class CableReadyChannels
    delegate :[], to: "cable_ready_channels"

    def initialize(reflex)
      @stream_name = reflex.stream_name
      @id = reflex.id
      CableReady.config.add_operation_name(:stimulus_reflex_version_mismatch)
    end

    def cable_ready_channels
      CableReady::Channels.instance
    end

    def stimulus_reflex_channel
      CableReady::Channels.instance[@stream_name]
    end

    def method_missing(name, *args)
      if stimulus_reflex_channel.respond_to?(name)
        if (options = args.find_index { |a| a.is_a? Hash })
          args[options][:reflex_id] = @id
        elsif args.any?
          args << {reflex_id: @id}
        end
        return stimulus_reflex_channel.public_send(name, *args)
      end
      super
    end

    def respond_to_missing?(name, include_all)
      stimulus_reflex_channel.respond_to?(name) || super
    end
  end
end
