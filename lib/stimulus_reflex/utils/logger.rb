# frozen_string_literal: true

module StimulusReflex
  class Logger
    attr_reader :logger
    attr_accessor :reflex, :current_operation

    delegate :debug, :info, :warn, :error, :fatal, :unknown, to: :logger

    def initialize(reflex)
      @reflex = reflex
      @current_operation = 1
      @logger = StimulusReflex.config.logger
    end

    def log_all_operations
      return unless config_logging.instance_of?(Proc)

      reflex.broadcaster.operations.each do
        logger.info instance_eval(&config_logging) + "\e[0m"
        @current_operation += 1
      end
    end

    private

    def config_logging
      return @config_logging if @config_logging

      return unless StimulusReflex.config.logging.instance_of?(Proc)

      StimulusReflex.config.logging.binding.eval("using StimulusReflex::Utils::Colorize")
      @config_logging = StimulusReflex.config.logging
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

    def id_full
      reflex.id
    end

    def id
      id_full[0..7]
    end

    # TODO: remove for v4
    def reflex_id_full
      reflex.reflex_id
    end

    def reflex_id
      reflex_id_full[0..7]
    end
    # END TODO remove

    def mode
      reflex.broadcaster.to_s
    end

    def selector
      reflex.broadcaster.operations[current_operation - 1][0]
    end

    def operation
      reflex.broadcaster.operations[current_operation - 1][1].to_s
    end

    def operation_counter
      current_operation.to_s + "/" + reflex.broadcaster.operations.size.to_s
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

    def method_missing(name, *args)
      return send(name) if private_instance_methods.include?(name.to_sym)

      reflex.connection.identifiers.each do |identifier|
        ident = reflex.connection.send(identifier)
        return ident.send(name) if ident.respond_to?(:attributes) && ident.attributes.key?(name.to_s)
      end
      "-"
    end

    def respond_to_missing?(name, include_all)
      return true if private_instance_methods.include?(name.to_sym)

      reflex.connection.identifiers.each do |identifier|
        ident = reflex.connection.send(identifier)
        return true if ident.respond_to?(:attributes) && ident.attributes.key?(name.to_s)
      end
      false
    end

    def private_instance_methods
      StimulusReflex::Logger.private_instance_methods(false)
    end
  end
end
