# frozen_string_literal: true

require "rails/generators"

class StimulusReflexGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  argument :name, type: :string, required: true, banner: "NAME"
  argument :actions, type: :array, default: [], banner: "action action"

  def execute
    actions.map!(&:underscore)

    copy_application_files if behavior == :invoke

    template "app/reflexes/%file_name%_reflex.rb"
    template "app/javascript/controllers/%file_name%_controller.js"
  end

  private

  def copy_application_files
    template "app/reflexes/application_reflex.rb"
    template "app/javascript/controllers/application_controller.js"
  end
end
