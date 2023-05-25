# frozen_string_literal: true

module StimulusReflex
  module CableReadiness
    attr_reader :cable_ready

    def initialize(*args, **kwargs)
      super(*args, **kwargs)

      if is_a? CableReady::Broadcaster
        message = <<~MSG

          #{self.class.name} includes CableReady::Broadcaster, and you need to remove it.
          Reflexes have their own CableReady interface. You can just assume that it's present.
          See https://docs.stimulusreflex.com/guide/cableready#using-cableready-inside-a-reflex-action for more details.

        MSG
        raise TypeError.new(message.strip)
      end
      @cable_ready = StimulusReflex::CableReadyChannels.new(self)
    end
  end
end
