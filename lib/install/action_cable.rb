# verify that Action Cable is installed
if defined?(ActionCable::Engine)
  say "✅ ActionCable::Engine is required and in scope"
else
  say "❌ ActionCable::Engine is not required. Please add or uncomment `require \"action_cable/engine\"` to your `config/application.rb`", :red
  create_file "tmp/stimulus_reflex_installer/halt", verbose: false
  return
end

# verify that the Action Cable pubsub config is created
cable_config = Rails.root.join("config/cable.yml")

if cable_config.exist?
  say "✅ config/cable.yml is present"
else
  inside "config" do
    template "cable.yml"
  end
end

# verify that the Action Cable pubsub is set to use redis in development
yaml = YAML.safe_load(File.read(cable_config))
app_name = Rails.application.class.module_parent.name.underscore

if yaml["development"]["adapter"] == "redis"
  say "✅ config/cable.yml is configured to use the redis adapter in development"
elsif yaml["development"]["adapter"] == "async"
  yaml["development"] = {
    "adapter" => "redis",
    "url" => "<%= ENV.fetch(\"REDIS_URL\") { \"redis://localhost:6379/1\" } %>",
    "channel_prefix" => "#{app_name}_development"
  }
  File.write(cable_config, yaml.to_yaml)
  say "✅ config/cable.yml was updated to use the redis adapter in development"
else
  say "❔ config/cable.yml should use the redis adapter - or something like it - in development. You have something else specified, and we trust that you know what you're doing."
end

# verify that the Action Cable channels folder and consumer class is available
entrypoint = File.read("tmp/stimulus_reflex_installer/entrypoint")
footgun = File.read("tmp/stimulus_reflex_installer/footgun")
templates_path = File.expand_path("../generators/stimulus_reflex/templates/app/javascript/channels", File.join(File.dirname(__FILE__)))
channels_path = Rails.root.join(entrypoint, "channels")
consumer_src = templates_path + "/consumer.js.tt"
consumer_path = channels_path.join("consumer.js")
index_src = templates_path + "/index.js.#{footgun}.tt"
index_path = channels_path.join("index.js")

empty_directory channels_path unless channels_path.exist?

copy_file(consumer_src, consumer_path) unless consumer_path.exist?

friendly_index_path = index_path.relative_path_from(Rails.root).to_s
if index_path.exist?
  if File.read(index_path) == File.read(index_src)
    say "✅ #{friendly_index_path} is present"
  else
    copy_file(index_path, "#{index_path}.bak", verbose: false)
    remove_file(index_path, verbose: false)
    copy_file(index_src, index_path, verbose: false)
    append_file("tmp/stimulus_reflex_installer/backups", "#{friendly_index_path}\n", verbose: false)
    say "#{friendly_index_path} has been created"
    say "❕ original index.js renamed index.js.bak", :yellow
  end
else
  copy_file(index_src, index_path)
end

pack_path = [
  Rails.root.join(entrypoint, "application.js"),
  Rails.root.join(entrypoint, "packs/application.js"),
  Rails.root.join(entrypoint, "entrypoints/application.js")
].find { |path| File.exist?(path) }

# don't proceed unless application pack exists
if pack_path.nil?
  say "❌ #{pack_path} is missing", :red
  create_file "tmp/stimulus_reflex_installer/halt", verbose: false
  return
end
friendly_pack_path = pack_path.relative_path_from(Rails.root).to_s

# import Action Cable channels into application pack
pack = File.read(pack_path)
channels_pattern = /import ['"](\.\/)?channels['"]/
channels_commented_pattern = /\s*\/\/\s*#{channels_pattern}/
prefix = {"vite" => "..\/", "webpacker" => "", "shakapacker" => "", "importmap" => "", "esbuild" => ".\/"}[footgun]
channel_import = "import \"#{prefix}channels\"\n"

if pack.match?(channels_pattern)
  if pack.match?(channels_commented_pattern)

    options_path = Rails.root.join("tmp/stimulus_reflex_installer/options")
    options = YAML.safe_load(File.read(options_path))

    proceed = if options.key? "uncomment"
      options["uncomment"]
    else
      !no?("Action Cable seems to be commented out in your application.js. Do you want to uncomment it? (Y/n)")
    end

    if proceed
      # uncomment_lines only works with Ruby comments 🙄
      lines = File.readlines(pack_path)
      matches = lines.select { |line| line =~ channels_commented_pattern }
      lines[lines.index(matches.last).to_i] = channel_import
      File.write(pack_path, lines.join)
      say "✅ channels imported in #{friendly_pack_path}"
    else
      say "❔ your Action Cable channels are not being imported in your application.js. We trust that you have a reason for this."
    end
  else
    say "✅ channels imported in #{friendly_pack_path}"
  end
else
  lines = File.readlines(pack_path)
  matches = lines.select { |line| line =~ /^import / }
  lines.insert lines.index(matches.last).to_i + 1, channel_import
  File.write(pack_path, lines.join)
  say "✅ channels imported in #{friendly_pack_path}"
end

create_file "tmp/stimulus_reflex_installer/action_cable", verbose: false
