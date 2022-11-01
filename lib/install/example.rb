reflex = Rails.root.join("app/reflexes/example_reflex.rb")

proceed = false
if !reflex.exist?
  puts

  options_path = Rails.root.join("tmp/stimulus_reflex_installer/options")
  options = YAML.safe_load(File.read(options_path))

  proceed = if options.key? "example"
    options["example"]
  else
    !no?("Generate an example Reflex with a quick demo? You can remove it later with a single commend. (Y/n)")
  end
end

generate("stimulus_reflex", "example", "dance") if proceed

create_file "tmp/stimulus_reflex_installer/example", verbose: false
