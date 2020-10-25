# frozen_string_literal: true

require "rails/generators"

module StimulusReflex
  module Generators
    class ConfigGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      # Generates default StimulusReflex configuration file into your application config/initializers directory.
      def copy_config_file
        copy_file "stimulus_reflex_config.rb", "config/initializers/stimulus_reflex.rb"
      end
    end
  end
end
