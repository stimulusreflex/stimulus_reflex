# frozen_string_literal: true

require "stimulus_reflex/installer"

return if pack_path_missing?

step_path = "/app/javascript/config/"
index_src = fetch(step_path, "index.js.tt")
index_path = config_path / "index.js"
stimulus_reflex_src = fetch(step_path, "stimulus_reflex.js.tt")
stimulus_reflex_path = config_path / "stimulus_reflex.js"
cable_ready_src = fetch(step_path, "cable_ready.js.tt")
cable_ready_path = config_path / "cable_ready.js"

empty_directory config_path unless config_path.exist?

backup(index_path, delete: true) do
  copy_file(index_src, index_path)
end

index_pattern = /import ['"](\.\.\/|\.\/)?config['"]/
index_commented_pattern = /\s*\/\/\s*#{index_pattern}/
index_import = "import \"#{prefix}config\"\n"

if pack.match?(index_pattern)
  if pack.match?(index_commented_pattern)
    lines = pack_path.readlines
    matches = lines.select { |line| line =~ index_commented_pattern }
    lines[lines.index(matches.last).to_i] = index_import
    pack_path.write lines.join
  end
else
  lines = pack_path.readlines
  matches = lines.select { |line| line =~ /^import / }
  lines.insert lines.index(matches.last).to_i + 1, index_import
  pack_path.write lines.join
end
say "✅ SR/CR configs will be imported in #{friendly_pack_path}"

# create entrypoint/config/cable_ready.js and make sure it's imported in application.js
copy_file(cable_ready_src, cable_ready_path) unless cable_ready_path.exist?

# create entrypoint/config/stimulus_reflex.js and make sure it's imported in application.js
copy_file(stimulus_reflex_src, stimulus_reflex_path) unless stimulus_reflex_path.exist?

if ["webpacker", "shakapacker"].include?(bundler)
  append_file(stimulus_reflex_path, <<~JS, verbose: false) unless stimulus_reflex_path.read.include?("StimulusReflex.debug")

    if (process.env.RAILS_ENV === 'development') {
      StimulusReflex.debug = true
      window.reflexes = StimulusReflex.reflexes
    }
  JS
elsif bundler == "vite"
  append_file(stimulus_reflex_path, <<~JS, verbose: false) unless stimulus_reflex_path.read.include?("StimulusReflex.debug")

    if (import.meta.env.MODE === "development") {
      StimulusReflex.debug = true
      window.reflexes = StimulusReflex.reflexes
    }
  JS
else
  append_file(stimulus_reflex_path, <<~JS, verbose: false) unless stimulus_reflex_path.read.include?("StimulusReflex.debug")

    // consider removing these options in production
    StimulusReflex.debug = true
    window.reflexes = StimulusReflex.reflexes
    // end remove
  JS
end
say "✅ Set useful development environment options"

complete_step :config
