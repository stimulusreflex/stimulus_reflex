# frozen_string_literal: true

require "uri"
require "rack"
require "rails/engine"
require "active_support/all"
require "action_dispatch"
require "action_cable"
require "nokogiri"
require "cable_ready"
require "stimulus_reflex/version"
require "stimulus_reflex/reflex"
require "stimulus_reflex/element"
require "stimulus_reflex/channel"
require "stimulus_reflex/broadcasters/broadcaster"
require "stimulus_reflex/broadcasters/nothing_broadcaster"
require "stimulus_reflex/broadcasters/page_broadcaster"
require "stimulus_reflex/broadcasters/selector_broadcaster"
require "generators/stimulus_reflex_generator"

module StimulusReflex
  class Engine < Rails::Engine
    initializer "stimulus_reflex.verify_caching_enabled" do
      unless caching_enabled?
        puts <<~WARN
          Stimulus Reflex requires caching to be enabled. Caching allows the session to be modified during ActionCable requests.
          To enable caching in development, run:

            rails dev:cache
        WARN
        exit
      end
    end

    private

    def caching_enabled?
      Rails.application.config.action_controller.perform_caching
    end
  end
end
