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
    attr_accessor :on_failed_sanity_checks, :parent_channel, :logging

    DEFAULT_LOGGING = ->(r) { "[#{r.session_id}] #{r.operation_counter.magenta} #{r.reflex_info.green} -> #{r.selector.cyan} via #{r.mode} Morph (#{r.operation.yellow})" }

    def initialize
      @on_failed_sanity_checks = :exit
      @parent_channel = "ApplicationCable::Channel"
      @logging = DEFAULT_LOGGING
    end
  end
end
