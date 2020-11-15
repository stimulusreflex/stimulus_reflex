# frozen_string_literal: true

require "rails/generators"

module StimulusReflex
  class ConfigGenerator < Rails::Generators::Base
    desc "Creates an StimulusReflex configuration file in config/initializers"
    source_root File.expand_path("templates", __dir__)

    def copy_config_file
      copy_file "config/initializers/stimulus_reflex.rb"
    end
  end
end
