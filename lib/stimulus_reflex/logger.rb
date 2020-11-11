# frozen_string_literal: true

module StimulusReflex
  class Logger
    attr_accessor :reflex, :current_operation

    COLORS = {
      red: "31",
      green: "32",
      yellow: "33",
      blue: "34",
      magenta: "35",
      cyan: "36",
      white: "37"
    }

    def initialize(reflex)
      @reflex = reflex
      @current_operation = 1
    end

    def print
      return if log.empty?
      puts
      reflex.broadcaster.operations.each do
        puts log.push("\e[0m").join
        @current_operation += 1
      end
      puts
    end

    private

    def log
      StimulusReflex.config.logging.map { |element| element.is_a?(Symbol) ? send(element) : element }
    end

    def session_id_full
      session = reflex.request&.session
      session.nil? ? "-" : session.id
    end

    def session_id
      session_id_full.to_s[0..7]
    end

    def reflex_info
      reflex.class.to_s + "#" + reflex.method_name
    end

    def reflex_id_full
      reflex.reflex_id
    end

    def reflex_id
      reflex_id_full[0..7]
    end

    def mode
      reflex.broadcaster.to_s
    end

    def selector
      reflex.broadcaster.operations[@current_operation - 1][0]
    end

    def operation
      reflex.broadcaster.operations[@current_operation - 1][1]
    end

    def total_operations
      reflex.broadcaster.operations.size
    end

    def connection_id_full
      identifier = reflex.connection&.connection_identifier
      identifier.empty? ? "-" : identifier
    end

    def connection_id
      connection_id_full[0..7]
    end

    def timestamp
      Time.now.strftime("%Y-%m-%d %H:%M:%S")
    end

    def method_missing method
      return "\e[#{COLORS[method]}m" if COLORS.key?(method)
      reflex.connection.identifiers.each do |identifier|
        ident = reflex.connection.send(identifier)
        return ident.send(method) if ident.respond_to?(:attributes) && ident.attributes.key?(method.to_s)
      end
      "-"
    end

    def respond_to_missing? method
      return true if COLORS.key?(method)
      reflex.connection.identifiers.each do |identifier|
        ident = reflex.connection.send(identifier)
        return true if ident.respond_to?(:attributes) && ident.attributes.key?(method.to_s)
      end
      false
    end
  end
end
