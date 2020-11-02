# frozen_string_literal: true

module StimulusReflex
  class Logger
    attr_accessor :reflex

    COLORS = {
      "black" => "0;30",
      "red" => "0;31",
      "green" => "0;32",
      "yellow" => "0;33",
      "blue" => "0;34",
      "magenta" => "0;35",
      "cyan" => "0;36",
      "white" => "0;37"
    }

    def initialize(reflex)
      @reflex = reflex
    end

    def print
      return if debugging? || log.empty?

      puts <<~WARN
        #{self.class} logging #{colorized_log_message}
      WARN
    end

    private

    def debugging?
      StimulusReflex.config.debug
    end

    def colorized_log_message
      log.map { |element| colorize(element) }.push("\e[0;0m").join(" ")
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

    def operation
      "#{broadcaster}: #{selectors}"
    end

    def broadcaster
      reflex.broadcaster.to_sym
    end

    def selectors
      reflex.selectors.last
    end

    def connection_id(identifier = reflex.connection&.connection_identifier)
      return "-" if identifier.nil?

      identifier
    end

    def timestamp
      Time.now.strftime("%Y-%m-%d %H:%M:%S")
    end
  end
end
