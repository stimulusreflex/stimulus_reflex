# frozen_string_literal: true

require "stimulus_reflex/installer"

return if StimulusReflex::Installer.pack_path_missing?

if !StimulusReflex::Installer.importmap_path.exist?
  StimulusReflex::Installer.halt "#{friendly_StimulusReflex::Installer.importmap_path} is missing. You need a valid importmap config file to proceed."
  return
end

importmap = StimulusReflex::Installer.importmap_path.read

StimulusReflex::Installer.backup(StimulusReflex::Installer.importmap_path) do
  if !importmap.include?("pin_all_from \"#{StimulusReflex::Installer.entrypoint}/controllers\"")
    append_file(StimulusReflex::Installer.importmap_path, <<~RUBY, verbose: false)
      pin_all_from "#{StimulusReflex::Installer.entrypoint}/controllers", under: "controllers"
    RUBY
    say "✅ pin_all_from controllers"
  else
    say "⏩ pin_all_from controllers already pinned. Skipping."
  end

  if !importmap.include?("pin_all_from \"#{StimulusReflex::Installer.entrypoint}/channels\"")
    append_file(StimulusReflex::Installer.importmap_path, <<~RUBY, verbose: false)
      pin_all_from "#{StimulusReflex::Installer.entrypoint}/channels", under: "channels"
    RUBY
    say "✅ pin_all_from channels"
  else
    say "⏩ pin_all_from channels already pinned. Skipping."
  end

  if !importmap.include?("pin_all_from \"#{StimulusReflex::Installer.entrypoint}/config\"")
    append_file(StimulusReflex::Installer.importmap_path, <<~RUBY, verbose: false)
      pin_all_from "#{StimulusReflex::Installer.entrypoint}/config", under: "config"
    RUBY
    say "✅ pin_all_from config"
  else
    say "⏩ pin_all_from config already pinned. Skipping."
  end

  if !importmap.include?("pin \"@rails/actioncable\"")
    append_file(StimulusReflex::Installer.importmap_path, <<~RUBY, verbose: false)
      pin "@rails/actioncable", to: "actioncable.esm.js", preload: true
    RUBY
    say "✅ pin @rails/actioncable"
  else
    say "⏩ @rails/actioncable already pinned. Skipping."
  end

  if !importmap.include?("pin \"@hotwired/stimulus\"")
    append_file(StimulusReflex::Installer.importmap_path, <<~RUBY, verbose: false)
      pin "@hotwired/stimulus", to: "stimulus.js", preload: true
    RUBY
    say "✅ pin @hotwired/stimulus"
  else
    say "⏩ @hotwired/stimulus already pinned. Skipping."
  end

  if !importmap.include?("pin \"morphdom\"")
    append_file(StimulusReflex::Installer.importmap_path, <<~RUBY, verbose: false)
      pin "morphdom", to: "https://ga.jspm.io/npm:morphdom@2.6.1/dist/morphdom.js", preload: true
    RUBY
    say "✅ pin morphdom"
  else
    say "⏩ morphdom already pinned. Skipping."
  end

  if !importmap.include?("pin \"cable_ready\"")
    append_file(StimulusReflex::Installer.importmap_path, <<~RUBY, verbose: false)
      pin "cable_ready", to: "cable_ready.js", preload: true
    RUBY
    say "✅ pin cable_ready"
  else
    say "⏩ cable_ready already pinned. Skipping."
  end

  if !importmap.include?("pin \"stimulus_reflex\"")
    append_file(StimulusReflex::Installer.importmap_path, <<~RUBY, verbose: false)
      pin "stimulus_reflex", to: "stimulus_reflex.js", preload: true
    RUBY
    say "✅ pin stimulus_reflex"
  else
    say "⏩ stimulus_reflex already pinned. Skipping."
  end
end

application_controller_src = StimulusReflex::Installer.fetch("/", "app/javascript/controllers/application_controller.js.tt")
application_controller_path = StimulusReflex::Installer.controllers_path / "application_controller.js"
application_js_src = StimulusReflex::Installer.fetch("/", "app/javascript/controllers/application.js.tt")
application_js_path = StimulusReflex::Installer.controllers_path / "application.js"
index_src = StimulusReflex::Installer.fetch("/", "app/javascript/controllers/index.js.importmap.tt")
index_path = StimulusReflex::Installer.controllers_path / "index.js"

# create entrypoint/controllers, as well as the index, application and application_controller
empty_directory StimulusReflex::Installer.controllers_path unless StimulusReflex::Installer.controllers_path.exist?

copy_file(application_controller_src, application_controller_path) unless application_controller_path.exist?

# configure Stimulus application superclass to import Action Cable consumer
StimulusReflex::Installer.backup(application_js_path) do
  if application_js_path.exist?
    friendly_application_js_path = application_js_path.relative_path_from(Rails.root).to_s
    if application_js_path.read.include?("import consumer")
      say "⏩ #{friendly_application_js_path} is present. Skipping."
    else
      inject_into_file application_js_path, "import consumer from \"channels/consumer\"\n", after: "import { Application } from \"@hotwired/stimulus\"\n", verbose: false
      inject_into_file application_js_path, "application.consumer = consumer\n", after: "application.debug = false\n", verbose: false
      say "✅ #{friendly_application_js_path} has been updated to import the Action Cable consumer"
    end
  else
    template(application_js_src, application_js_path)
    say "✅ #{friendly_application_js_path} has been created"
  end
end

if index_path.exist?
  friendly_index_path = index_path.relative_path_from(Rails.root).to_s

  if index_path.read == index_src.read
    say "⏩ #{friendly_index_path} is present. Skipping"
  else
    StimulusReflex::Installer.backup(index_path, delete: true) do
      copy_file(index_src, index_path, verbose: false)
    end
    say "✅ #{friendly_index_path} has been updated"
  end
else
  copy_file(index_src, index_path)
  say "✅ #{friendly_index_path} has been created."
end

StimulusReflex::Installer.complete_step :importmap
