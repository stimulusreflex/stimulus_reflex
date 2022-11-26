working = Rails.root.join("tmp/stimulus_reflex_installer/working")

development_working = Rails.root.join(working, "development.rb")
development_path = Rails.root.join("config/environments/development.rb")
FileUtils.cp(development_working, development_path)
say "✅ development environment configuration installed"

initializer_working = Rails.root.join(working, "action_cable.rb")
if initializer_working.exist?
  initializer_path = Rails.root.join("config/initializers/action_cable.rb")
  FileUtils.cp(initializer_working, initializer_path)
  say "✅ Action Cable initializer installed"
end

create_file "tmp/stimulus_reflex_installer/finalize", verbose: false
