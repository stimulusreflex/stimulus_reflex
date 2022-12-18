require "stimulus_reflex/installer"

proceed = false
if !Rails.root.join("app/reflexes/example_reflex.rb").exist?
  puts

  proceed = if options.key? "example"
    options["example"]
  else
    !no?("Generate an example Reflex with a quick demo? You can remove it later with a single commend. (Y/n)")
  end
end

generate("stimulus_reflex", "example", "dance") if proceed

complete_step :example
