entrypoint = File.read("tmp/stimulus_reflex_installer/entrypoint")
config_path = Rails.root.join(entrypoint, "config")
templates_path = File.expand_path("../generators/stimulus_reflex/templates/app/javascript/config", File.join(File.dirname(__FILE__)))
stimulus_reflex_src = templates_path + "/stimulus_reflex.js.tt"
stimulus_reflex_path = config_path.join("stimulus_reflex.js")
cable_ready_src = templates_path + "/cable_ready.js.tt"
cable_ready_path = config_path.join("cable_ready.js")

# support esbuild and webpacker
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

empty_directory config_path unless config_path.exist?

# create entrypoint/config/cable_ready.js and make sure it's imported in application.js
copy_file(cable_ready_src, cable_ready_path) unless File.exist?(cable_ready_path)

pack = File.read(pack_path)
friendly_pack_path = pack_path.relative_path_from(Rails.root).to_s
footgun = File.read("tmp/stimulus_reflex_installer/footgun")
cr_pattern = /import ['"].\/config\/cable_ready['"]/
cr_commented_pattern = /\s*\/\/\s*#{cr_pattern}/
cr_import = {
  "webpacker" => "import \"config\/cable_ready\"\n",
  "esbuild" => "import \".\/config\/cable_ready\"\n"
}

if pack.match?(cr_pattern)
  if pack.match?(cr_commented_pattern)
    if !no?("CableReady seems to be commented out in your application.js. Do you want to enable it? (Y/n)")
      # uncomment_lines only works with Ruby comments 🙄
      lines = File.readlines(pack_path)
      matches = lines.select { |line| line =~ cr_commented_pattern }
      lines[lines.index(matches.last).to_i] = cr_import[footgun]
      File.write(pack_path, lines.join)
      say "✅ CableReady will be imported in #{friendly_pack_path}"
    else
      say "❔ CableReady is not being imported in your application.js. We trust that you have a reason for this."
    end
  else
    say "✅ CableReady will be imported in #{friendly_pack_path}"
  end
else
  lines = File.readlines(pack_path)
  matches = lines.select { |line| line =~ /^import / }
  lines.insert lines.index(matches.last).to_i + 1, cr_import[footgun]
  File.write(pack_path, lines.join)
  say "✅ CableReady will be imported in #{friendly_pack_path}"
end

# create entrypoint/config/stimulus_reflex.js and make sure it's imported in application.js
copy_file(stimulus_reflex_src, stimulus_reflex_path) unless File.exist?(stimulus_reflex_path)

pack = File.read(pack_path)
sr_pattern = /import ['"].\/config\/stimulus_reflex['"]/
sr_commented_pattern = /\s*\/\/\s*#{sr_pattern}/
sr_import = {
  "webpacker" => "import \"config\/stimulus_reflex\"\n",
  "esbuild" => "import \".\/config\/stimulus_reflex\"\n"
}

if pack.match?(sr_pattern)
  if pack.match?(sr_commented_pattern)
    if !no?("StimulusReflex seems to be commented out in your application.js. Do you want to enable it? (Y/n)")
      # uncomment_lines only works with Ruby comments 🙄
      lines = File.readlines(pack_path)
      matches = lines.select { |line| line =~ sr_commented_pattern }
      lines[lines.index(matches.last).to_i] = sr_import[footgun]
      File.write(pack_path, lines.join)
      say "✅ StimulusReflex will be imported in #{friendly_pack_path}"
    else
      say "❔ StimulusReflex is not being imported in your application.js. We trust that you have a reason for this."
    end
  else
    say "✅ StimulusReflex will be imported in #{friendly_pack_path}"
  end
else
  lines = File.readlines(pack_path)
  matches = lines.select { |line| line =~ /^import / }
  lines.insert lines.index(matches.last).to_i + 1, sr_import[footgun]
  File.write(pack_path, lines.join)
  say "✅ StimulusReflex will be imported in #{friendly_pack_path}"
end

create_file "tmp/stimulus_reflex_installer/config", verbose: false
