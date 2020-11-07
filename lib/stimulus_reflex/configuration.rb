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
    attr_accessor :exit_on_failed_sanity_checks, :parent_channel, :debug, :logging

    def initialize
      @exit_on_failed_sanity_checks = true
      @parent_channel = "ApplicationCable::Channel"
      @debug = false
      @logging = []
    end
  end
end
