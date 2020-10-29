# frozen_string_literal: true

module StimulusReflex
  class << self
    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    alias config configuration
  end

  class Configuration
    attr_accessor :exit_on_failed_sanity_checks

    def initialize
      @exit_on_failed_sanity_checks = true
    end
  end
end
