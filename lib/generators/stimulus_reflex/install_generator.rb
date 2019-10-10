module StimulusReflex
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      def copy_reflex_files
        copy_file "application_reflex.rb", "app/reflexes/application_reflex.rb"
        copy_file "example_reflex.rb", "app/reflexes/#{file_name}_reflex.rb"
      end

      def copy_controller_files
        copy_file "example_controller.js", "app/javascript/controllers/#{file_name}_controller.js"
        copy_file "application_controller.js", "app/javascript/controllers/application_controller.js"
      end
    end
  end
end
