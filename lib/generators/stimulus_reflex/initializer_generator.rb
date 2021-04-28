# frozen_string_literal: true

require "rails/generators"

module StimulusReflex
  class InitializerGenerator < Rails::Generators::Base
    desc "Creates a StimulusReflex initializer in config/initializers"
    source_root File.expand_path("templates", __dir__)

    def copy_initializer_file
      copy_file "config/initializers/stimulus_reflex.rb"
    end
  end
end
