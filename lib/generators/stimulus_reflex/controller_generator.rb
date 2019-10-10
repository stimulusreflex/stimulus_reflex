module StimulusReflex
  module Generators
    class ControllerGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)

      def copy_controller_file
        copy_file "example_controller.js", "app/javascript/controllers/#{file_name}_controller.js"
      end
    end
  end
end
