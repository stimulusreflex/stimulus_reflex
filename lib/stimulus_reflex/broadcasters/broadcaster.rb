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

    def broadcast_message(subject:, data: {}, error: nil)
      operations << ["document", :dispatch_event]
      cable_ready.dispatch_event(
        name: "stimulus-reflex:server-message",
        detail: {
          reflexId: data.delete("reflexId"),
          payload: payload,
          stimulus_reflex: data.merge(
            morph: to_sym,
            server_message: {subject: subject, body: error&.to_s}
          )
        }
      )
      cable_ready.broadcast
    end

    # abstract method to be implemented by subclasses
    def broadcast(*args)
      raise NotImplementedError
    end

    # abstract method to be implemented by subclasses
    def to_sym
      raise NotImplementedError
    end

    # abstract method to be implemented by subclasses
    def to_s
      raise NotImplementedError
    end
  end
end
