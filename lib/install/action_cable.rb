# verify that Action Cable is installed
if defined?(ActionCable::Engine)
  say "✅ ActionCable::Engine is required and in scope"
else
  say "❌ ActionCable::Engine is not required. Please add `require \"action_cable/engine\"` to your `config/application.rb`", :red
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
channels_path = Rails.root.join(entrypoint, "channels")
consumer_path = channels_path.join("consumer.js")
index_path = channels_path.join("index.js")

empty_directory channels_path unless channels_path.exist?

inside "app/javascript/channels" do # this is the correct relative path for these assets in railties
  copy_file("consumer.js", consumer_path) unless consumer_path.exist?
  copy_file("index.js", index_path) unless index_path.exist?
end

# support esbuild and webpacker
pack_path = [
  Rails.root.join(entrypoint, "application.js"),
  Rails.root.join(entrypoint, "packs/application.js")
].find { |path| File.exist?(path) }

# don't proceed unless application pack exists
if !pack_path.exist?
  say "❌ #{pack_path} is missing", :red
  create_file "tmp/stimulus_reflex_installer/halt", verbose: false
  return
end

# import Action Cable channels into application pack
pack = File.read(pack_path)
channels_pattern = /import ['"]channels['"]/
channels_commented_pattern = /\s*\/\/\s*#{channels_pattern}/

if pack.match?(channels_pattern)
  if pack.match?(channels_commented_pattern)
    if !no?("Action Cable seems to be commented out in your application.js. Do you want to uncomment it? (Y/n)")
      # uncomment_lines only works with Ruby comments 🙄
      lines = File.readlines(pack_path)
      matches = lines.select { |line| line =~ channels_commented_pattern }
      lines[lines.index(matches.last).to_i] = "import \"channels\"\n"
      File.write(pack_path, lines.join)
      say "✅ channels imported in app/javascript/packs/application.js"
    else
      say "❔ your Action Cable channels are not being imported in your application.js. We trust that you have a reason for this."
    end
  else
    say "✅ channels imported in app/javascript/packs/application.js"
  end
else
  lines = File.readlines(pack_path)
  matches = lines.select { |line| line =~ /^import / }
  lines.insert lines.index(matches.last).to_i + 1, "import \"channels\"\n"
  File.write(pack_path, lines.join)
  say "✅ channels imported in app/javascript/packs/application.js"
end

create_file "tmp/stimulus_reflex_installer/action_cable", verbose: false
