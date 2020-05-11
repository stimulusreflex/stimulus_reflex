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
require "stimulus_reflex/service/reflex_invoker"
require "stimulus_reflex/transport/base_adapter"
require "stimulus_reflex/transport/cable_ready_adapter"
require "stimulus_reflex/transport/message_bus_adapter"
require "generators/stimulus_reflex_generator"

module StimulusReflex
  class Engine < Rails::Engine
    isolate_namespace StimulusReflex
    engine_name "stimulus_reflex"
  end
end
