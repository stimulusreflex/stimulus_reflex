# frozen_string_literal: true

require "stimulus_reflex/installer"

proceed = false
if !Rails.root.join("app/reflexes/example_reflex.rb").exist?
  proceed = if StimulusReflex::Installer.options.key? "example"
    StimulusReflex::Installer.options["example"]
  else
    !no?("✨ Generate an example Reflex with a quick demo? You can remove it later with a single command. (Y/n)")
  end
else
  say "⏩ app/reflexes/example_reflex.rb already exists."
end

if proceed
  generate("stimulus_reflex", "example")
else
  say "⏩ Skipping."
end

StimulusReflex::Installer.complete_step :example
