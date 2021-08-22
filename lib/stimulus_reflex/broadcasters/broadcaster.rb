# frozen_string_literal: true

module StimulusReflex
  class Broadcaster
    attr_reader :reflex, :logger, :operations
    delegate :cable_ready, :permanent_attribute_name, :payload, to: :reflex

    DEFAULT_HTML_WITHOUT_FORMAT = Nokogiri::XML::Node::SaveOptions::DEFAULT_HTML &
      ~Nokogiri::XML::Node::SaveOptions::FORMAT

    def initialize(reflex)
      @reflex = reflex
      @logger = Rails.logger if defined?(Rails.logger)
      @operations = []
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

    def halted(data: {})
      operations << ["document", :dispatch_event]
      cable_ready.dispatch_event(
        name: "stimulus-reflex:morph-halted",
        payload: payload,
        stimulus_reflex: data.merge(morph: to_sym)
      ).broadcast
    end

    def error(data: {}, body: nil)
      operations << ["document", :dispatch_event]
      cable_ready.dispatch_event(
        name: "stimulus-reflex:morph-error",
        payload: payload,
        stimulus_reflex: data.merge(morph: to_sym),
        body: body&.to_s
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
