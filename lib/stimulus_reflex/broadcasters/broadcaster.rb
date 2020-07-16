# frozen_string_literal: true

module StimulusReflex
  class Broadcaster
    include CableReady::Broadcaster

    attr_reader :reflex
    delegate :stream_name, to: :reflex

    def initialize(reflex)
      @reflex = reflex
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

    def broadcast_message(subject:, body: nil, data: {})
      message = {
        subject: subject,
        body: body
      }

      logger.error "\e[31m#{body}\e[0m" if subject == "error"

      data[:morph_mode] = "page"
      data[:server_message] = message
      data[:morph_mode] = "selector" if subject == "selector"
      data[:morph_mode] = "nothing" if subject == "nothing"

      cable_ready[stream_name].dispatch_event(
        name: "stimulus-reflex:server-message",
        detail: {stimulus_reflex: data}
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
