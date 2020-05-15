# frozen_string_literal: true

require "rails/generators"

class StimulusReflexGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  def initialize_application_reflexes
    copy_application_files if behavior == :invoke
  end

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
    template "custom_reflex.rb", File.join(REFLEX_BASE_PATH, "#{name.underscore}_reflex.rb")
  end

  def copy_controller_files
    template "custom_controller.js", File.join(CONTROLLER_BASE_PATH, "#{name.underscore}_controller.js")
  end

  def copy_application_files
    template "application_reflex.rb", File.join(REFLEX_BASE_PATH, "application_reflex.rb")
    template "application_controller.js", File.join(CONTROLLER_BASE_PATH, "application_controller.js")
  end
end
