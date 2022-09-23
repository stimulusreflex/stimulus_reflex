reflex = Rails.root.join("app/reflexes/example_reflex.rb")

proceed = false
if !reflex.exist?
  puts
  proceed = !no?("Generate an example Reflex with a quick demo? You can remove it later with a single commend. (Y/n)")
end

generate("stimulus_reflex", "example", "dance") if proceed

create_file "tmp/stimulus_reflex_installer/example", verbose: false
