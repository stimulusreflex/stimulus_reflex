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

    def initialize
      @on_failed_sanity_checks = :exit
      @parent_channel = "ApplicationCable::Channel"
      @logging = ->(r) { "#{r.timestamp} #{r.red} [#{r.session_id}] #{r.magenta} #{r.operation_counter} #{r.green} #{r.reflex_info} -> #{r.white} ##{r.selector} #{r.yellow} #{r.operation} #{r.white} via #{r.blue} #{r.mode} Morph #{r.cyan} to #{r.connection_id}" }
    end
  end
end
