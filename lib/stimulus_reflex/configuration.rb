# frozen_string_literal: true

module StimulusReflex
  class << self
    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    alias_method :config, :configuration
  end

  class Configuration
    attr_accessor :on_failed_sanity_checks, :on_missing_default_urls, :parent_channel, :logging, :logger, :middleware, :morph_operation, :replace_operation, :precompile_assets

    DEFAULT_LOGGING = proc { "[#{session_id}] #{operation_counter.magenta} #{reflex_info.green} -> #{selector.cyan} via #{mode} Morph (#{operation.yellow})" }

    def on_new_version_available
      warn "NOTICE: The `config.on_new_version_available` option has been removed from the StimulusReflex initializer. You can safely remove this option from your initializer."
    end

    def on_new_version_available=(_)
      warn "NOTICE: The `config.on_new_version_available` option has been removed from the StimulusReflex initializer. You can safely remove this option from your initializer."
    end

    def initialize
      @on_failed_sanity_checks = :exit
      @on_missing_default_urls = :warn
      @parent_channel = "ApplicationCable::Channel"
      @logging = DEFAULT_LOGGING
      @logger = Rails.logger
      @middleware = ActionDispatch::MiddlewareStack.new
      @morph_operation = :morph
      @replace_operation = :inner_html
      @precompile_assets = true
    end
  end
end
