# frozen_string_literal: true

require "rails/engine"

module StimulusReflex
  class Engine < ::Rails::Engine
    initializer "stimulus_reflex.sanity_check" do
      SanityChecker.check! unless Rails.env.production?
    end

    # If you don't want to precompile StimulusReflex's assets (eg. because you're using webpack),
    # you can do this in an initializer:
    #
    # config.after_initialize do
    #   config.assets.precompile -= StimulusReflex::Engine::PRECOMPILE_ASSETS
    # end
    #
    PRECOMPILE_ASSETS = %w[
      stimulus_reflex.js
      stimulus_reflex.umd.js
    ]

    initializer "stimulus_reflex.assets" do |app|
      if app.config.respond_to?(:assets) && StimulusReflex.config.precompile_assets
        app.config.assets.precompile += PRECOMPILE_ASSETS
      end
    end

    initializer "stimulus_reflex.importmap", before: "importmap" do |app|
      if app.config.respond_to?(:importmap)
        app.config.importmap.paths << Engine.root.join("lib/stimulus_reflex/importmap.rb")
        app.config.importmap.cache_sweepers << Engine.root.join("app/assets/javascripts")
      end
    end
  end
end
