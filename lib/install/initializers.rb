sr_initializer_path = Rails.root.join("config/initializers/stimulus_reflex.rb")
cr_initializer_path = Rails.root.join("config/initializers/cable_ready.rb")

generate "stimulus_reflex:initializer" unless sr_initializer_path.exist?
say "✅ StimulusReflex initializer created at config/initializers/stimulus_reflex.rb"

generate "cable_ready:initializer" unless cr_initializer_path.exist?
say "✅ CableReady initializer created at config/initializers/cable_ready.rb"

create_file "tmp/stimulus_reflex_installer/initializers", verbose: false
