# frozen_string_literal: true

require "stimulus_reflex/installer"

return if pack_path_missing?

step_path = "/app/javascript/config/"
index_src = fetch(step_path, "index.js.tt")
index_path = config_path / "index.js"
friendly_index_path = index_path.relative_path_from(Rails.root).to_s
stimulus_reflex_src = fetch(step_path, "stimulus_reflex.js.tt")
stimulus_reflex_path = config_path / "stimulus_reflex.js"
friendly_stimulus_reflex_path = stimulus_reflex_path.relative_path_from(Rails.root).to_s
cable_ready_src = fetch(step_path, "cable_ready.js.tt")
cable_ready_path = config_path / "cable_ready.js"

empty_directory config_path unless config_path.exist?

if index_path.exist?
  say "⏩ #{friendly_index_path} already exists. Skipping"
else
  backup(index_path, delete: true) do
    template(index_src, index_path)
  end
  say "✅ Created #{friendly_index_path}"
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

    say "✅ Uncommented StimulusReflex and CableReady configs imports in #{friendly_pack_path}"
  else
    say "⏩ StimulusReflex and CableReady configs are already being imported in #{friendly_pack_path}. Skipping"
  end
else
  lines = pack_path.readlines
  matches = lines.select { |line| line =~ /^import / }
  lines.insert lines.index(matches.last).to_i + 1, index_import
  pack_path.write lines.join

  say "✅ StimulusReflex and CableReady configs will be imported in #{friendly_pack_path}"
end

# create entrypoint/config/cable_ready.js and make sure it's imported in application.js
template(cable_ready_src, cable_ready_path) unless cable_ready_path.exist?

# create entrypoint/config/stimulus_reflex.js and make sure it's imported in application.js
template(stimulus_reflex_src, stimulus_reflex_path) unless stimulus_reflex_path.exist?

if stimulus_reflex_path.read.include?("StimulusReflex.debug =")
  say "⏩ Development environment options are already set in #{friendly_stimulus_reflex_path}. Skipping"
else
  if bundler.webpacker? || bundler.shakapacker?
    append_file(stimulus_reflex_path, <<~JS, verbose: false)

      if (process.env.RAILS_ENV === 'development') {
        StimulusReflex.debug = true
      }
    JS
  elsif bundler.vite?
    append_file(stimulus_reflex_path, <<~JS, verbose: false) unless stimulus_reflex_path.read.include?("StimulusReflex.debug")

      if (import.meta.env.MODE === "development") {
        StimulusReflex.debug = true
      }
    JS
  else
    append_file(stimulus_reflex_path, <<~JS, verbose: false)

      // consider removing these options in production
      StimulusReflex.debug = true
      // end remove
    JS
  end

  say "✅ Set useful development environment options in #{friendly_stimulus_reflex_path}"
end

complete_step :config
