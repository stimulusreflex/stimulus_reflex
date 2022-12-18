require "stimulus_reflex/version"
require "cable_ready/version"

### general utilities

def fetch(step_path, file)
  relative_path = step_path + file
  location = template_src + relative_path
  return Pathname.new(location) if ENV["LOCAL"] == "true"

  begin
    local_file = Rails.root.join(working, location)
    FileUtils.mkdir_p(working.to_s + relative_path.split("/")[0..-2].join("/"))
    timeout = YAML.safe_load(File.read(options_path))["timeout"]
    local_file.write(URI.open("https://raw.githubusercontent.com/stimulusreflex/stimulus_reflex/#{ENV["GITHUB_BRANCH"]}/lib/generators/stimulus_reflex/templates#{relative_path}", open_timeout: timeout, read_timeout: timeout).read.strip)
    local_file
  rescue
    create_or_append(network_issue_path, current_template + "\n", verbose: false)
    Pathname.new(location)
  end
end

def complete_step(step)
  create_file "tmp/stimulus_reflex_installer/#{step}", verbose: false
end

def create_or_append(path, *args, &block)
  FileUtils.touch(path)
  append_file(path, *args, &block)
end

def current_template
  ENV["LOCATION"].split("/").last.gsub(".rb", "")
end

def pack_path_missing?
  return false unless pack_path.nil?
  halt "#{friendly_pack_path} is missing. You need a valid application pack file to proceed."
end

def halt(message)
  say "❌ #{message}", :red
  create_file "tmp/stimulus_reflex_installer/halt", verbose: false
end

def backup(path, delete: false)
  backup_path = Pathname.new("#{path}.bak")
  old_path = path.relative_path_from(Rails.root).to_s
  filename = path.to_path.split("/").last

  if backup_path.exist?
    if backup_path.read == path.read
      path.delete if delete
      yield
      return
    end
    backup_path.delete
  end

  copy_file(path, backup_path, verbose: false)
  path.delete if delete

  yield

  if path.read != backup_path.read
    create_or_append(backups_path, "#{old_path}\n", verbose: false)
  end
  say "📦 #{old_path} backed up as #{filename}.bak"
end

def add_gem(name)
  create_or_append(add_gem_list, "#{name}\n", verbose: false)
  say "➕ Added #{name} to the Gemfile"
end

def remove_gem(name)
  create_or_append(remove_gem_list, "#{name}\n", verbose: false)
  say "➖ Removed #{name} from Gemfile"
end

def add_package(name)
  create_or_append(package_list, "#{name}\n", verbose: false)
  say "➕ Enqueued #{name} to be added to dependencies"
end

def add_dev_package(name)
  create_or_append(dev_package_list, "#{name}\n", verbose: false)
  say "➕ Enqueued #{name} to be added to dev dependencies"
end

def drop_package(name)
  create_or_append(drop_package_list, "#{name}\n", verbose: false)
  say "➖ Enqueued #{name} to be removed from dependencies"
end

def gemfile_hash
  Digest::MD5.hexdigest(gemfile_path.read)
end

### memoized values

def sr_npm_version
  @sr_npm_version ||= StimulusReflex::VERSION.gsub(".pre", "-pre")
end

def cr_npm_version
  @cr_npm_version ||= CableReady::VERSION.gsub(".pre", "-pre")
end

def package_json
  @package_json ||= Rails.root.join("package.json")
end

def entrypoint
  @entrypoint ||= File.read("tmp/stimulus_reflex_installer/entrypoint")
end

def footgun
  @footgun ||= File.read("tmp/stimulus_reflex_installer/footgun")
end

def network_issue_path
  @network_issue_path ||= Rails.root.join("tmp/stimulus_reflex_installer/network_issue")
end

def config_path
  @config_path ||= Rails.root.join(entrypoint, "config")
end

def importmap_path
  @importmap_path ||= Rails.root.join("config/importmap.rb")
end

def friendly_importmap_path
  @friendly_importmap_path ||= importmap_path.relative_path_from(Rails.root).to_s
end

def pack
  @pack ||= pack_path.read
end

def friendly_pack_path
  @friendly_pack_path ||= pack_path.relative_path_from(Rails.root).to_s
end

def pack_path
  @pack_path ||= [
    Rails.root.join(entrypoint, "application.js"),
    Rails.root.join(entrypoint, "packs/application.js"),
    Rails.root.join(entrypoint, "entrypoints/application.js")
  ].find(&:exist?)
end

def package_list
  @package_list ||= Rails.root.join("tmp/stimulus_reflex_installer/npm_package_list")
end

def dev_package_list
  @dev_package_list ||= Rails.root.join("tmp/stimulus_reflex_installer/npm_dev_package_list")
end

def drop_package_list
  @drop_package_list ||= Rails.root.join("tmp/stimulus_reflex_installer/drop_npm_package_list")
end

def template_src
  @template_src ||= File.read("tmp/stimulus_reflex_installer/template_src")
end

def controllers_path
  @controllers_path ||= Rails.root.join(entrypoint, "controllers")
end

def gemfile_path
  @gemfile_path ||= Rails.root.join("Gemfile")
end

def gemfile
  @gemfile ||= gemfile_path.read
end

def prefix
  @prefix ||= {
    "vite" => "..\/",
    "webpacker" => "",
    "shakapacker" => "",
    "importmap" => "",
    "esbuild" => ".\/"
  }[footgun]
end

def application_record_path
  @application_record_path ||= Rails.root.join("app/models/application_record.rb")
end

def action_cable_initializer_path
  @action_cable_initializer_path ||= Rails.root.join("config/initializers/action_cable.rb")
end

def action_cable_initializer_working_path
  @action_cable_initializer_working_path ||= Rails.root.join(working, "action_cable.rb")
end

def development_path
  @development_path ||= Rails.root.join("config/environments/development.rb")
end

def development_working_path
  @development_working_path ||= Rails.root.join(working, "development.rb")
end

def backups_path
  @backups_path ||= Rails.root.join("tmp/stimulus_reflex_installer/backups")
end

def add_gem_list
  @add_gem_list ||= Rails.root.join("tmp/stimulus_reflex_installer/add_gem_list")
end

def remove_gem_list
  @remove_gem_list ||= Rails.root.join("tmp/stimulus_reflex_installer/remove_gem_list")
end

def options_path
  @options_path ||= Rails.root.join("tmp/stimulus_reflex_installer/options")
end

def options
  @options ||= YAML.safe_load(File.read(options_path))
end

def working
  @working ||= Rails.root.join("tmp/stimulus_reflex_installer/working")
end

### support for development step

def write_redis_recommendation(development_working, lines, index, gemfile)
  # provide a recommendation for using redis-session-store, including commented source code
  if !lines.index { |line| line.include?("StimulusReflex does not support :cookie_store") }
    lines.insert index + 1, <<RUBY

  # StimulusReflex does not support :cookie_store, and we recommend switching to Redis.
  # To use `redis-session-store`, make sure to add it to your Gemfile and run `bundle install`.

  # config.session_store :redis_session_store,
  #   serializer: :json,
  #   on_redis_down: ->(*a) { Rails.logger.error("Redis down! \#{a.inspect}") },
  #   redis: {
  #     expire_after: 120.minutes,
  #     key_prefix: "session:",
  #     url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" }
  # }
RUBY
    development_working.write lines.join
    # add redis-session-store to Gemfile, but comment it out
    if !gemfile.match?(/gem ['"]redis-session-store['"]/)
      append_file(gemfile_path, verbose: false) do
        <<~RUBY

          # StimulusReflex recommends using Redis for session storage
          # gem "redis-session-store", "0.11.5"
        RUBY
      end
      say "💡 Added redis-session-store 0.11.5 to the Gemfile, commented out"
    end
  end
end

def find_index(lines)
  # accomodate devs who modify their development.rb file structure
  if (index = lines.index { |line| line =~ /caching-dev/ })
    index += 3
  else
    index = lines.index { |line| line =~ /^Rails.application.configure do/ } + 1
  end
  index
end
