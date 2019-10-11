require_relative './application_generator'

module StimulusReflex
  module Generators
    class StimulusReflexGenerator < Rails::Generators::NamedBase
      include ApplicationGenerator

      source_root File.expand_path('templates', __dir__)

      def initialize_reflexes
        copy_reflex_files
      end

      def initialize_controllers
        copy_controller_files
      end
    end
  end
end
