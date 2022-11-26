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
    File.write(development_working, lines.join)
    # add redis-session-store to Gemfile, but comment it out
    if !File.read(gemfile).match?(/gem ['"]redis-session-store['"]/)
      append_file(gemfile, verbose: false) do
        <<~RUBY

          # StimulusReflex recommends using Redis for session storage
          # gem "redis-session-store", "0.11.4"
        RUBY
      end
      say "💡 Added redis-session-store 0.11.4 to the Gemfile, commented out"
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

development = Rails.root.join("config/environments/development.rb")
working = Rails.root.join("tmp/stimulus_reflex_installer/working")
FileUtils.mkdir_p(working)
development_working = Rails.root.join(working, "development.rb")
FileUtils.cp(development, development_working)

# add default_url_options to development.rb for Action Mailer
if defined?(ActionMailer)
  lines = File.readlines(development_working)
  unless lines.find { |line| line.include?("config.action_mailer.default_url_options") }
    index = lines.index { |line| line =~ /^Rails.application.configure do/ }
    lines.insert index + 1, "  config.action_mailer.default_url_options = {host: \"localhost\", port: 3000}\n\n"
    File.write(development_working, lines.join)
  end
  say "✅ Action Mailer default_url_options defined"
end

# add default_url_options to development.rb for Action Controller
lines = File.readlines(development_working)
unless lines.find { |line| line.include?("config.action_controller.default_url_options") }
  index = lines.index { |line| line =~ /^Rails.application.configure do/ }
  lines.insert index + 1, "  config.action_controller.default_url_options = {host: \"localhost\", port: 3000}\n"
  File.write(development_working, lines.join)
end
say "✅ Action Controller default_url_options defined"

gemfile = Rails.root.join("Gemfile")
lines = File.readlines(development_working)

# halt with instructions if using cookie store, otherwise, nudge towards Redis
if (index = lines.index { |line| line =~ /^[^#]*config.session_store/ })
  if /^[^#]*cookie_store/.match?(lines[index])
    write_redis_recommendation(development_working, lines, index, gemfile)
    say "❌ StimulusReflex does not support session cookies. See https://docs.stimulusreflex.com/hello-world/setup#session-storage", :red
    create_file "tmp/stimulus_reflex_installer/halt", verbose: false
    return
  elsif /^[^#]*redis_session_store/.match?(lines[index])
    say "✅ Using redis-session-store for session storage"
  else
    write_redis_recommendation(development_working, lines, index, gemfile)
    say "❔ We recommend using redis-session-store for session storage. See https://docs.stimulusreflex.com/hello-world/setup#session-storage"
  end
# no session store defined, so let's opt-in to redis-session-store
else
  add_gem_list = Rails.root.join("tmp/stimulus_reflex_installer/add_gem_list")

  # add redis v4 to be compatible with redis-session-store
  if File.read(gemfile).match?(/gem ['"]redis['"]/)
    FileUtils.touch(add_gem_list)
    append_file(add_gem_list, "redis@>= 4\", \"< 5\n", verbose: false)
    say "✅ Enqueued redis to be added to the Gemfile"
  end

  # add redis-session-store to Gemfile
  if !File.read(gemfile).match?(/gem ['"]redis-session-store['"]/)
    FileUtils.touch(add_gem_list)
    append_file(add_gem_list, "redis-session-store@~> 0.11.4\n", verbose: false)
    say "✅ Enqueued redis-session-store 0.11.4 to be added to the Gemfile"
  end

  index = lines.index { |line| line =~ /^Rails.application.configure do/ }
  lines.insert index + 1, <<~RUBY
  
    config.session_store :redis_session_store,
      serializer: :json,
      on_redis_down: ->(*a) { Rails.logger.error("Redis down! \#{a.inspect}") },
      redis: {
        expire_after: 120.minutes,
        key_prefix: "session:",
        url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" }
      }
  RUBY
  File.write(development_working, lines.join)
  say "✅ Using redis-session-store for session storage"
end

# switch to redis for caching if using memory store, otherwise nudge with a comment
lines = File.readlines(development_working)
if (index = lines.index { |line| line =~ /^[^#]*config.cache_store = :memory_store/ })
  lines[index] = <<~RUBY
    config.cache_store = :redis_cache_store, {
      url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" }
    }
  RUBY
  File.write(development_working, lines.join)
  say "✅ Using Redis for caching"
elsif lines.index { |line| line =~ /^[^#]*config.cache_store = :redis_cache_store/ }
  say "✅ Using Redis for caching"
else
  if !lines.index { |line| line.include?("We couldn't identify your cache store") }
    lines.insert find_index(lines), <<~RUBY

      # We couldn't identify your cache store, but recommend using Redis:

      # config.cache_store = :redis_cache_store, {
      #   url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" }
      # }
    RUBY
    File.write(development_working, lines.join)
  end
  say "❔ We couldn't identify your cache store, but recommend using Redis. See https://docs.stimulusreflex.com/appendices/deployment#use-redis-as-your-cache-store"
end

create_file "tmp/stimulus_reflex_installer/development", verbose: false
