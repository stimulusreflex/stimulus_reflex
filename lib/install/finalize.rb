working = Rails.root.join("tmp/stimulus_reflex_installer/working")

development_working_path = Rails.root.join(working, "development.rb")
development_path = Rails.root.join("config/environments/development.rb")
FileUtils.cp(development_working_path, development_path)
say "✅ development environment configuration installed"

initializer_working_path = Rails.root.join(working, "action_cable.rb")
initializer_path = Rails.root.join("config/initializers/action_cable.rb")
FileUtils.cp(initializer_working_path, initializer_path)
say "✅ Action Cable initializer installed"

create_file "tmp/stimulus_reflex_installer/finalize", verbose: false
