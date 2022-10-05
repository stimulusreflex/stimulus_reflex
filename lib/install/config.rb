entrypoint = File.read("tmp/stimulus_reflex_installer/entrypoint")

pack_path = [
  Rails.root.join(entrypoint, "application.js"),
  Rails.root.join(entrypoint, "packs/application.js")
].find { |path| File.exist?(path) }

# don't proceed unless application pack exists
if pack_path.nil?
  say "❌ #{pack_path} is missing", :red
  create_file "tmp/stimulus_reflex_installer/halt", verbose: false
  return
end

footgun = File.read("tmp/stimulus_reflex_installer/footgun")
config_path = Rails.root.join(entrypoint, "config")
templates_path = File.expand_path("../generators/stimulus_reflex/templates/app/javascript/config", File.join(File.dirname(__FILE__)))
index_src = templates_path + "/index.js.tt"
index_path = config_path.join("index.js")
stimulus_reflex_src = templates_path + "/stimulus_reflex.js.tt"
stimulus_reflex_path = config_path.join("stimulus_reflex.js")
cable_ready_src = templates_path + "/cable_ready.js.tt"
cable_ready_path = config_path.join("cable_ready.js")

pack = File.read(pack_path)
friendly_pack_path = pack_path.relative_path_from(Rails.root).to_s

empty_directory config_path unless config_path.exist?

copy_file(index_src, index_path) unless File.exist?(index_path)

index_pattern = /import ['"].\/config['"]/
index_commented_pattern = /\s*\/\/\s*#{index_pattern}/
prefix = footgun == "esbuild" ? ".\/" : ""
index_import = "import \"#{prefix}config\"\n"

if pack.match?(index_pattern)
  if pack.match?(index_commented_pattern)
    lines = File.readlines(pack_path)
    matches = lines.select { |line| line =~ index_commented_pattern }
    lines[lines.index(matches.last).to_i] = index_import
    File.write(pack_path, lines.join)
  end
else
  lines = File.readlines(pack_path)
  matches = lines.select { |line| line =~ /^import / }
  lines.insert lines.index(matches.last).to_i + 1, index_import
  File.write(pack_path, lines.join)
end
say "✅ SR/CR configs will be imported in #{friendly_pack_path}"

# create entrypoint/config/cable_ready.js and make sure it's imported in application.js
copy_file(cable_ready_src, cable_ready_path) unless File.exist?(cable_ready_path)

# create entrypoint/config/stimulus_reflex.js and make sure it's imported in application.js
copy_file(stimulus_reflex_src, stimulus_reflex_path) unless File.exist?(stimulus_reflex_path)

if footgun == "webpacker"
  append_file(stimulus_reflex_path, <<~JS, verbose: false) unless File.read(stimulus_reflex_path).include?("StimulusReflex.debug")

    if (process.env.RAILS_ENV === 'development') {
      StimulusReflex.debug = true
      window.reflexes = StimulusReflex.reflexes
    }
  JS
else
  append_file(stimulus_reflex_path, <<~JS, verbose: false) unless File.read(stimulus_reflex_path).include?("StimulusReflex.debug")

    // consider removing these options in production
    StimulusReflex.debug = true
    window.reflexes = StimulusReflex.reflexes
    // end remove
  JS
end
say "✅ Set useful development environment options"

create_file "tmp/stimulus_reflex_installer/config", verbose: false
