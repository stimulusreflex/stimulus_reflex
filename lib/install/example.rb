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

if ENV["LOCAL"] == "true"
  generate("stimulus_reflex", "example", "--local true") if proceed
elsif proceed
  generate("stimulus_reflex", "example")
end

complete_step :example
