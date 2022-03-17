require "rails/engine"

module StimulusReflex
  class Engine < ::Rails::Engine
    initializer "stimulus_reflex.sanity_check" do
      SanityChecker.check! unless Rails.env.production?
    end

    initializer "stimulus_reflex.assets" do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.precompile += %w[stimulus_reflex.js stimulus_reflex.min.js stimulus_reflex.min.js.map]
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
