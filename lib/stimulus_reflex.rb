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
    NODE_VERSION_FORMAT = /(\d\.\d\.\d.*):/

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

    initializer "stimulus_reflex.verify_npm_package_version" do
      unless node_version_matches?
        puts <<~WARN
          The Stimulus Reflex javascript package version (#{node_package_version}) does not match the Rubygem version (#{gem_version}).
          To update the Stimulus Reflex node module:

            yarn upgrade stimulus_reflex@#{gem_version}
        WARN
        exit
      end
    end

    private

    def caching_enabled?
      Rails.application.config.action_controller.perform_caching &&
        Rails.application.config.cache_store != :null_store
    end

    def node_version_matches?
      node_package_version == gem_version
    end

    def gem_version
      StimulusReflex::VERSION.gsub(".pre", "-pre")
    end

    def node_package_version
      File.foreach(yarn_lock_path).grep(/^stimulus_reflex/).first[NODE_VERSION_FORMAT, 1]
    end

    def yarn_lock_path
      Rails.root.join("yarn.lock")
    end
  end
end
