# frozen_string_literal: true

require 'uri'
require 'rack'
require 'rails/engine'
require 'active_support/all'
require 'action_dispatch'
require 'action_cable'
require 'nokogiri'
require 'cable_ready'
require 'stimulus_reflex/version'
require 'stimulus_reflex/reflex'
require 'stimulus_reflex/element'
require 'stimulus_reflex/rails/actioncable/channel/base'
require 'stimulus_reflex/channel'
require 'generators/stimulus_reflex_generator'

module StimulusReflex
  class Engine < Rails::Engine
  end
end
