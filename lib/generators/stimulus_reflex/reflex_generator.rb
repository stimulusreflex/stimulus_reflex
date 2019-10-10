module StimulusReflex
  module Generators
    class ReflexGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)

      def copy_reflex_file
        copy_file "example_reflex.rb", "app/reflexes/#{file_name}_reflex.rb"
      end
    end
  end
end
