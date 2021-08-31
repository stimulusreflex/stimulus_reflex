# frozen_string_literal: true

require "rails/generators"

class StimulusReflexGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  argument :name, type: :string, required: true, banner: "NAME"
  argument :actions, type: :array, default: [], banner: "action action"
  class_options skip_stimulus: false, skip_app_reflex: false, skip_reflex: false, skip_app_controller: false

  def execute
    actions.map!(&:underscore)

    copy_application_files if behavior == :invoke

    template "app/reflexes/%file_name%_reflex.rb" unless options[:skip_reflex]
    template "app/javascript/controllers/%file_name%_controller.js" unless options[:skip_stimulus]
  end

  private

  def copy_application_files
    template "app/reflexes/application_reflex.rb" unless options[:skip_app_reflex]
    template "app/javascript/controllers/application_controller.js" unless options[:skip_app_controller]
  end
end
