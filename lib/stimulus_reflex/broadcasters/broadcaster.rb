# frozen_string_literal: true

module StimulusReflex
  class Broadcaster
    attr_reader :reflex, :cable_ready, :logger, :operations
    delegate :permanent_attribute_name, :payload, to: :reflex

    def initialize(reflex)
      @reflex = reflex
      @logger = Rails.logger if defined?(Rails.logger)
      @operations = []
      @cable_ready = StimulusReflex::CableReadyChannels.new(reflex)
    end

    def nothing?
      false
    end

    def page?
      false
    end

    def selector?
      false
    end

    def broadcast_halt(data: {})
      operations << ["document", :dispatch_event]
      cable_ready.dispatch_event(
        name: "stimulus-reflex:morph-halted",
        payload: payload,
        stimulus_reflex: data.merge(morph: to_sym)
      ).broadcast
    end

    def broadcast_forbid(data: {})
      operations << ["document", :dispatch_event]
      cable_ready.dispatch_event(
        name: "stimulus-reflex:morph-forbidden",
        payload: payload,
        stimulus_reflex: data.merge(morph: to_sym)
      ).broadcast
    end

    def broadcast_error(data: {}, error: nil)
      operations << ["document", :dispatch_event]
      cable_ready.dispatch_event(
        name: "stimulus-reflex:morph-error",
        payload: payload,
        stimulus_reflex: data.merge(morph: to_sym),
        error: error&.to_s
      ).broadcast
    end

    # abstract methods to be implemented by subclasses
    def broadcast(*args)
      raise NotImplementedError
    end

    def to_sym
      raise NotImplementedError
    end

    def to_s
      raise NotImplementedError
    end
  end
end
