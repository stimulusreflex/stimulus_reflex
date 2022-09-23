# frozen_string_literal: true

require "rails/generators"

module StimulusReflex
  class InitializerGenerator < Rails::Generators::Base
    desc "Creates a StimulusReflex initializer in config/initializers"
    source_root File.expand_path("templates", __dir__)

    def copy_initializer_file
      initializer_path = Rails.root.join("config/initializers/stimulus_reflex.rb")
      copy_file "config/initializers/stimulus_reflex.rb" unless initializer_path.exist?
    end
  end
end
