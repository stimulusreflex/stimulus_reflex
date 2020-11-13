# frozen_string_literal: true

module StimulusReflex
  class Broadcaster
    include CableReady::Broadcaster

    attr_reader :reflex, :logger
    delegate :permanent_attribute_name, :stream_name, to: :reflex

    def initialize(reflex)
      @reflex = reflex
      @logger = Rails.logger if defined?(Rails.logger)
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

    def broadcast_message(subject:, body: nil, data: {}, error: nil)
      logger.error "\e[31m#{body}\e[0m" if subject == "error"
      cable_ready[stream_name].dispatch_event(
        name: "stimulus-reflex:server-message",
        detail: {
          reflexId: data["reflexId"],
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
  end
end
