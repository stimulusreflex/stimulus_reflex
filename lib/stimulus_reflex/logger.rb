# frozen_string_literal: true

module StimulusReflex
	class Logger
		attr_accessor :reflex, :log_type

		LOG_TYPE_TO_COLOR_CODE = {
			error: "0;31",
			success: "0;32",
			halted: "0;33"
		}.freeze

		def initialize(reflex)
			@reflex = reflex
		end

		def print
			return unless debugging?

			colorized_log_message
		end

		private

		def debugging?
			StimulusReflex.config.debugging
		end

		def colorized_log_message
			return if log.empty?

			puts <<~WARN
				#{colorize("#{self.class} logging #{log_type} for reflex action:")}
				#{colorize(formatted_log_message)}
			WARN
		end

		def log
			@log ||= StimulusReflex.config.logging.each_with_object({}) { |log_level, h| h[log_level] = send(log_level) }
		end

		def colorize(message, color = LOG_TYPE_TO_COLOR_CODE[log_type.to_sym])
			"\e[#{color}m#{message}\e[0;0m"
		end

		def formatted_log_message
			log.values.to_sentence(words_connector: " ", last_word_connector: " ")
		end

		def session_id(session = reflex.request&.session)
			return '-' if session.nil?

			"[#{session.id}]"
		end

		def reflex_name(dataset = reflex.element&.dataset)
			return '-' if dataset.nil?

			dataset.reflex.split("->").last
		end

		def operation
			"(#{broadcaster}: ##{selectors})"
		end

		def broadcaster
			reflex.broadcaster.to_sym
		end

		def selectors
			reflex.selectors.last
		end

		def connection_id(identifier = reflex.connection&.connection_identifier)
			return '-' if identifier.nil?
			
			"for #{identifier}"
		end

		def timestamp
			"at #{Time.now}"
		end
	end
end
