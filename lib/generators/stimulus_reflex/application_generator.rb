module StimulusReflex
  module Generators
    module ApplicationGenerator
      CONTROLLER_BASE_PATH = "app/javascript/controllers"
      APPLICATION_CONTROLLER_FILE_PATH = "#{CONTROLLER_BASE_PATH}/application_controller.js"

      REFLEX_BASE_PATH = "app/reflexes"
      APPLICATION_REFLEX_FILE_PATH = "#{REFLEX_BASE_PATH}/application_reflex.rb"

      def copy_reflex_files
        unless File.exist?(APPLICATION_REFLEX_FILE_PATH)
          copy_file "application_reflex.rb", APPLICATION_REFLEX_FILE_PATH
        end
        template "example_reflex.rb.erb", "#{REFLEX_BASE_PATH}/#{file_name}_reflex.rb"
      end

      def copy_controller_files
        unless File.exist?(APPLICATION_CONTROLLER_FILE_PATH)
          copy_file "application_controller.js", APPLICATION_CONTROLLER_FILE_PATH
        end
        copy_file "example_controller.js", "#{CONTROLLER_BASE_PATH}/#{file_name}_controller.js"
      end
    end
  end
end
