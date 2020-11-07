# frozen_string_literal: true

module StimulusReflex
  class Logger
    attr_accessor :reflex

    COLORS = {
      "black" => "30",
      "red" => "31",
      "green" => "32",
      "yellow" => "33",
      "blue" => "34",
      "magenta" => "35",
      "cyan" => "36",
      "white" => "37"
    }

    def initialize(reflex)
      @reflex = reflex
    end

    def print
			return if debugging? || log.empty?

      Kernel.print("#{self.class} logging #{colorized_log_message}")
    end

    private

    def debugging?
      StimulusReflex.config.debug
    end

		def colorized_log_message
      log.map { |element| colorize(element) }.push("\e[0m").join
    end

    def colorize(element)
      return element unless COLORS.key?(element)

      "\e[#{COLORS[element]}m"
		end

		def log
      @log ||= StimulusReflex.config.logging.map { |element| element.is_a?(Symbol) ? send(element) : element }
    end

    def session_id(session = reflex.request&.session)
      return "-" if session.nil?

      session.id
    end

    def reflex_name(dataset = reflex.element&.dataset)
      return "-" if dataset.nil?

      dataset.reflex.split("->").last
    end

    def broadcaster
      reflex.broadcaster.to_sym
    end

    def selector
      reflex.selectors.last
    end

		def connection_id(identifier = reflex.connection&.connection_identifier)
      return "-" if identifier.empty?

      identifier
    end

    def timestamp
      Time.now.strftime("%Y-%m-%d %H:%M:%S")
    end
  end
end
