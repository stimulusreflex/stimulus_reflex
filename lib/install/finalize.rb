working = Rails.root.join("tmp/stimulus_reflex_installer/working")

model_path = "app/models/application_record.rb"
if Rails.root.join(model_path).exist?
  lines = File.readlines(model_path)
  if !lines.index { |line| line =~ /^\s*include CableReady::Updatable/ }
    index = lines.index { |line| line.include?("class ApplicationRecord < ActiveRecord::Base") }
    lines.insert index + 1, "  include CableReady::Updatable\n"
    File.write(model_path, lines.join)
  end
  puts "✅ include CableReady::Updatable in Active Record model classes"
end

development_working_path = Rails.root.join(working, "development.rb")
development_path = Rails.root.join("config/environments/development.rb")
FileUtils.cp(development_working_path, development_path)
say "✅ development environment configuration installed"

initializer_working_path = Rails.root.join(working, "action_cable.rb")
initializer_path = Rails.root.join("config/initializers/action_cable.rb")
FileUtils.cp(initializer_working_path, initializer_path)
say "✅ Action Cable initializer installed"

create_file "tmp/stimulus_reflex_installer/finalize", verbose: false
