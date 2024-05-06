# frozen_string_literal: true

require "stimulus_reflex/installer"

return if StimulusReflex::Installer.pack_path_missing?

# verify that all critical dependencies are up to date; if not, queue for later
lines = StimulusReflex::Installer.package_json_path.readlines

if !lines.index { |line| line =~ /^\s*["']esbuild-rails["']: ["']\^1.0.3["']/ }
  StimulusReflex::Installer.add_package "esbuild-rails@^1.0.3"
else
  say "⏩ esbuild-rails npm package is already present. Skipping."
end

# copy esbuild.config.mjs to app root
esbuild_src = StimulusReflex::Installer.fetch("/", "esbuild.config.mjs.tt")
esbuild_path = Rails.root.join("esbuild.config.mjs")

if esbuild_path.exist?
  if esbuild_path.read == esbuild_src.read
    say "⏩ esbuild.config.mjs already present in app root. Skipping."
  else
    StimulusReflex::Installer.backup(esbuild_path) do
      template(esbuild_src, esbuild_path, verbose: false, entrypoint: StimulusReflex::Installer.entrypoint)
    end
    say "✅ updated esbuild.config.mjs in app root"
  end
else
  template(esbuild_src, esbuild_path, entrypoint: StimulusReflex::Installer.entrypoint)
  say "✅ Created esbuild.config.mjs in app root"
end

step_path = "/app/javascript/controllers/"
application_controller_src = StimulusReflex::Installer.fetch(step_path, "application_controller.js.tt")
application_controller_path = StimulusReflex::Installer.controllers_path / "application_controller.js"
application_js_src = StimulusReflex::Installer.fetch(step_path, "application.js.tt")
application_js_path = StimulusReflex::Installer.controllers_path / "application.js"
index_src = StimulusReflex::Installer.fetch(step_path, "index.js.esbuild.tt")
index_path = StimulusReflex::Installer.controllers_path / "index.js"
friendly_index_path = index_path.relative_path_from(Rails.root).to_s

# create entrypoint/controllers, if necessary
empty_directory StimulusReflex::Installer.controllers_path unless StimulusReflex::Installer.controllers_path.exist?

# copy application_controller.js, if necessary
copy_file(application_controller_src, application_controller_path) unless application_controller_path.exist?

# configure Stimulus application superclass to import Action Cable consumer
friendly_application_js_path = application_js_path.relative_path_from(Rails.root).to_s

if application_js_path.exist?
  StimulusReflex::Installer.backup(application_js_path) do
    if application_js_path.read.include?("import consumer")
      say "⏩ #{friendly_application_js_path} is already present. Skipping."
    else
      inject_into_file application_js_path, "import consumer from \"../channels/consumer\"\n", after: "import { Application } from \"@hotwired/stimulus\"\n", verbose: false
      inject_into_file application_js_path, "application.consumer = consumer\n", after: "application.debug = false\n", verbose: false
      say "✅ #{friendly_application_js_path} has been updated to import the Action Cable consumer"
    end
  end
else
  copy_file(application_js_src, application_js_path)
  say "✅ #{friendly_application_js_path} has been created"
end

if index_path.exist?
  if index_path.read == index_src.read
    say "⏩ #{friendly_index_path} already present. Skipping."
  else
    StimulusReflex::Installer.backup(index_path, delete: true) do
      copy_file(index_src, index_path, verbose: false)
    end

    say "✅ #{friendly_index_path} has been updated"
  end
else
  copy_file(index_src, index_path)
  say "✅ #{friendly_index_path} has been created"
end

controllers_pattern = /import ['"].\/controllers['"]/
controllers_commented_pattern = /\s*\/\/\s*#{controllers_pattern}/

if StimulusReflex::Installer.pack.match?(controllers_pattern)
  if StimulusReflex::Installer.pack.match?(controllers_commented_pattern)
    proceed = if StimulusReflex::Installer.options.key? "uncomment"
      StimulusReflex::Installer.options["uncomment"]
    else
      !no?("✨ Stimulus seems to be commented out in your application.js. Do you want to import your controllers? (Y/n)")
    end

    if proceed
      # uncomment_lines only works with Ruby comments 🙄
      lines = StimulusReflex::Installer.pack_path.readlines
      matches = lines.select { |line| line =~ controllers_commented_pattern }
      lines[lines.index(matches.last).to_i] = "import \".\/controllers\"\n" # standard:disable Style/RedundantStringEscape
      StimulusReflex::Installer.pack_path.write lines.join
      say "✅ Uncommented Stimulus controllers import in #{StimulusReflex::Installer.friendly_pack_path}"
    else
      say "🤷 your Stimulus controllers are not being imported in your application.js. We trust that you have a reason for this."
    end
  else
    say "⏩ Stimulus controllers are already being imported in #{StimulusReflex::Installer.friendly_pack_path}. Skipping."
  end
else
  lines = StimulusReflex::Installer.pack_path.readlines
  matches = lines.select { |line| line =~ /^import / }
  lines.insert lines.index(matches.last).to_i + 1, "import \".\/controllers\"\n" # standard:disable Style/RedundantStringEscape
  StimulusReflex::Installer.pack_path.write lines.join
  say "✅ Stimulus controllers imported in #{StimulusReflex::Installer.friendly_pack_path}"
end

StimulusReflex::Installer.complete_step :esbuild
