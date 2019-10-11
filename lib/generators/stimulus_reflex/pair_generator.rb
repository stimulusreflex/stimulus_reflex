module StimulusReflex
  module Generators
    class PairGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      def initialize_reflexes
        copy_reflex_files
      end

      def initialize_controllers
        copy_controller_files
      end

      private

      CONTROLLER_BASE_PATH = "app/javascript/controllers"
      REFLEX_BASE_PATH = "app/reflexes"

      def copy_reflex_files
        filepath = File.join(REFLEX_BASE_PATH, "application_reflex.rb")
        template "application_reflex.rb", filepath unless File.exist?(filepath)

        filepath = File.join(REFLEX_BASE_PATH, "#{name.underscore}_reflex.rb")
        template "custom_reflex.rb", filepath unless File.exist?(filepath)
      end

      def copy_controller_files
        filepath = File.join(CONTROLLER_BASE_PATH, "application_controller.js")
        template "application_controller.js", filepath unless File.exist?(filepath)

        filepath = File.join(CONTROLLER_BASE_PATH, "#{name.underscore}_controller.js")
        template "custom_controller.js", filepath unless File.exist?(filepath)
      end
    end
  end
end
