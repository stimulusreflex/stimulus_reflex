def write_redis_recommendation(development, lines, index)
  gemfile = Rails.root.join("Gemfile")
  redis_pattern = /gem ['"]redis-session-store['"]/

  # add redis-session-store to Gemfile, but comment it out
  if !File.read(gemfile).match?(redis_pattern)
    append_file gemfile, "\n# Use Redis for session storage"
    gem "redis-session-store", "0.11.4"
    comment_lines gemfile, redis_pattern
  end

  # provide a recommendation for using redis-session-store, including commented source code
  if !lines.index { |line| line.include?("StimulusReflex does not support :cookie_store") }
    lines.insert index + 1, <<RUBY

  # StimulusReflex does not support :cookie_store, and we recommend switching to Redis.
  # https://docs.stimulusreflex.com/appendices/deployment#use-redis-as-your-cache-store

  # To use `redis-session-store`, make sure to add it to your Gemfile and run `bundle install`.

  # config.session_store :redis_session_store, {
  #   serializer: :json,
  #   on_redis_down: ->(*a) { logger.error("Redis down! \#{a.inspect}") },
  #   redis: {
  #     expire_after: 120.minutes,
  #     key_prefix: "session:",
  #     url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" }
  #   }
  # }
RUBY
    File.write(development, lines.join)
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

# add default_url_options to development.rb for Action Mailer
if defined?(ActionMailer)
  lines = File.readlines(development)
  unless lines.find { |line| line.include?("config.action_mailer.default_url_options") }
    index = lines.index { |line| line =~ /^Rails.application.configure do/ }
    lines.insert index + 1, "  config.action_mailer.default_url_options = {host: \"localhost\", port: 3000}\n\n"
    File.write(development, lines.join)
  end
  say "✅ Action Mailer default_url_options defined"
end

# add default_url_options to development.rb for Action Controller
lines = File.readlines(development)
unless lines.find { |line| line.include?("config.action_controller.default_url_options") }
  index = lines.index { |line| line =~ /^Rails.application.configure do/ }
  lines.insert index + 1, "  config.action_controller.default_url_options = {host: \"localhost\", port: 3000}\n"
  File.write(development, lines.join)
end
say "✅ Action Controller default_url_options defined"

# halt with instructions if using cookie store, otherwise, nudge towards Redis
lines = File.readlines(development)
if (index = lines.index { |line| line =~ /^[^#]*config.session_store/ })
  if /^[^#]*cookie_store/.match?(lines[index])
    write_redis_recommendation(development, lines, index)
    say "❌ StimulusReflex does not support session cookies. See config/environments/development.rb for more information", :red
    create_file "tmp/stimulus_reflex_installer/halt", verbose: false
    return
  elsif /^[^#]*redis_session_store/.match?(lines[index])
    say "✅ Using redis-session-store for session storage"
  else
    write_redis_recommendation(development, lines, index)
    say "❔ We recommend using redis-session-store for session storage. See config/environments/development.rb for more information"
  end
else
  # no session store defined, so let's add Redis
  index = lines.index { |line| line =~ /^Rails.application.configure do/ }
  lines.insert index + 1, <<RUBY

  config.session_store :redis_session_store, {
    serializer: :json,
    on_redis_down: ->(*a) { logger.error("Redis down! \#{a.inspect}") },
    redis: {
      expire_after: 120.minutes,
      key_prefix: "session:",
      url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" }
    }
  }
RUBY
  File.write(development, lines.join)
  say "✅ Using redis-session-store for session storage"

  gemfile = Rails.root.join("Gemfile")
  redis_pattern = /gem ['"]redis['"]/
  redis_session_store_pattern = /gem ['"]redis-session-store['"]/

  # uncomment redis in Gemfile
  if File.read(gemfile).match?(redis_pattern)
    uncomment_lines gemfile, redis_pattern, verbose: false
    say "✅ Redis gem uncommented in Gemfile"
  end

  # add redis-session-store to Gemfile
  if !File.read(gemfile).match?(redis_session_store_pattern)
    append_file gemfile, "\n# Use Redis for session storage"
    gem "redis-session-store", "0.11.4"
  end
  say "✅ Added redis-session-store to Gemfile"
end

# switch to redis for caching if using memory store, otherwise nudge with a comment
lines = File.readlines(development)
if (index = lines.index { |line| line =~ /^[^#]*config.cache_store = :memory_store/ })
  lines[index] = <<RUBY
    config.cache_store = :redis_cache_store, {
      url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" }
    }
RUBY
  File.write(development, lines.join)
  say "✅ Using Redis for caching"
elsif lines.index { |line| line =~ /^[^#]*config.cache_store = :redis_cache_store/ }
  say "✅ Using Redis for caching"
else
  if !lines.index { |line| line.include?("We couldn't identify your cache store") }
    lines.insert find_index(lines), <<RUBY

  # We couldn't identify your cache store, but recommend using Redis:

  # config.cache_store = :redis_cache_store, {
  #   url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" }
  # }
RUBY
    File.write(development, lines.join)
  end
  say "❔ We couldn't identify your cache store, but recommend using Redis. See config/environments/development.rb for more information"
end

# Enable caching in development
if !Rails.root.join("tmp/caching-dev.txt").exist?
  system "rails dev:cache"
  puts
end

create_file "tmp/stimulus_reflex_installer/development", verbose: false
