# frozen_string_literal: true

require "stimulus_reflex/installer"

sr_initializer_src = StimulusReflex::Installer.fetch("/", "config/initializers/stimulus_reflex.rb")
sr_initializer_path = Rails.root.join("config/initializers/stimulus_reflex.rb")

cr_initializer_src = StimulusReflex::Installer.fetch("/", "config/initializers/cable_ready.rb")
cr_initializer_path = Rails.root.join("config/initializers/cable_ready.rb")

if !sr_initializer_path.exist?
  copy_file(sr_initializer_src, sr_initializer_path, verbose: false)
  say "✅ StimulusReflex initializer created at config/initializers/stimulus_reflex.rb"
else
  say "⏩ config/initializers/stimulus_reflex.rb already exists. Skipping."
end

if !cr_initializer_path.exist?
  copy_file(cr_initializer_src, cr_initializer_path, verbose: false)
  say "✅ CableReady initializer created at config/initializers/cable_ready.rb"
else
  say "⏩ config/initializers/cable_ready.rb already exists. Skipping."
end

StimulusReflex::Installer.complete_step :initializers
