# frozen_string_literal: true

require "rails/generators"

class StimulusReflexGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  argument :name, type: :string, required: true, banner: "NAME"
  argument :actions, type: :array, default: [], banner: "action action"
  class_options skip_stimulus: false, skip_reflex: false

  def execute
    actions.map!(&:underscore)

    cached_entrypoint = Rails.root.join("tmp/stimulus_reflex_installer/entrypoint")
    if cached_entrypoint.exist?
      entrypoint = File.read(cached_entrypoint)
    else
      entrypoint = [
        "app/javascript",
        "app/frontend"
      ].find { |path| File.exist?(Rails.root.join(path)) } || "app/javascript"
      puts "Where do JavaScript files live in your app? Our best guess is: \e[1#{entrypoint}\e[22m 🤔"
      puts "Press enter to accept this, or type a different path."
      print "> "
      input = Rails.env.test? ? "tmp/app/javascript" : $stdin.gets.chomp
      entrypoint = input unless input.blank?
    end

    if !options[:skip_stimulus] && entrypoint.blank?
      puts "❌ You must specify a valid JavaScript entrypoint."
      exit
    end

    stimulus_class_entrypoint = Rails.env.test? ? "tmp/app/reflexes" : "app/reflexes"
    stimulus_class_src = "app/reflexes/%file_name%_reflex.rb.tt"
    stimulus_class_path = Rails.root.join(stimulus_class_entrypoint, "#{file_name}_reflex.rb")
    stimulus_controller_src = "app/javascript/controllers/%file_name%_controller.js.tt"
    stimulus_controller_path = Rails.root.join(entrypoint, "controllers/#{file_name}_controller.js")

    template(stimulus_class_src, stimulus_class_path) unless options[:skip_reflex]
    template(stimulus_controller_src, stimulus_controller_path) unless options[:skip_stimulus]

    if file_name == "example"
      controller_src = "app/controllers/example_controller.rb.tt"
      controller_path = Rails.root.join("app/controllers/example_controller.rb")
      template(controller_src, controller_path)

      view_src = "app/views/example/index.html.erb.tt"
      view_path = Rails.root.join("app/views/example/index.html.erb")
      template(view_src, view_path)

      FileUtils.remove_dir("app/views/example") if behavior == :revoke && Dir.empty?(Rails.root.join("app/views/example"))

      route "get '/example', to: 'example#index', constraints: -> { Rails.env.development? }"
    end
  end
end
