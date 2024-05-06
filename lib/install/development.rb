# frozen_string_literal: true

require "stimulus_reflex/installer"

# mutate working copy of development.rb to avoid bundle alerts
FileUtils.cp(StimulusReflex::Installer.development_path, StimulusReflex::Installer.development_working_path)

# add default_url_options to development.rb for Action Mailer
if defined?(ActionMailer)
  lines = StimulusReflex::Installer.development_working_path.readlines
  if lines.find { |line| line.include?("config.action_mailer.default_url_options") }
    say "⏩ Action Mailer default_url_options already defined. Skipping."
  else
    index = lines.index { |line| line =~ /^Rails.application.configure do/ }
    lines.insert index + 1, "  config.action_mailer.default_url_options = {host: \"localhost\", port: 3000}\n\n"
    StimulusReflex::Installer.development_working_path.write lines.join

    say "✅ Action Mailer default_url_options defined"
  end
end

# add default_url_options to development.rb for Action Controller
lines = StimulusReflex::Installer.development_working_path.readlines
if lines.find { |line| line.include?("config.action_controller.default_url_options") }
  say "⏩ Action Controller default_url_options already defined. Skipping."
else
  index = lines.index { |line| line =~ /^Rails.application.configure do/ }
  lines.insert index + 1, "  config.action_controller.default_url_options = {host: \"localhost\", port: 3000}\n"
  StimulusReflex::Installer.development_working_path.write lines.join

  say "✅ Action Controller default_url_options defined"
end

# StimulusReflex::Installer.halt with instructions if using cookie store, otherwise, nudge towards Redis
lines = StimulusReflex::Installer.development_working_path.readlines

if (index = lines.index { |line| line =~ /^[^#]*config.session_store/ })
  if /^[^#]*cookie_store/.match?(lines[index])
    StimulusReflex::Installer.write_redis_recommendation(StimulusReflex::Installer.development_working_path, lines, index, StimulusReflex::Installer.gemfile)
    StimulusReflex::Installer.halt "StimulusReflex does not support session cookies. See https://docs.stimulusreflex.com/hello-world/setup#session-storage"
    return
  elsif /^[^#]*redis_session_store/.match?(lines[index])
    say "⏩ Already using redis-session-store for session storage. Skipping."
  else
    StimulusReflex::Installer.write_redis_recommendation(StimulusReflex::Installer.development_working_path, lines, index, StimulusReflex::Installer.gemfile)
    say "🤷 We recommend using redis-session-store for session storage. See https://docs.stimulusreflex.com/hello-world/setup#session-storage"
  end
# no session store defined, so let's opt-in to redis-session-store
else
  # add redis-session-store to Gemfile
  if !StimulusReflex::Installer.gemfile.match?(/gem ['"]redis-session-store['"]/)
    if ActionCable::VERSION::MAJOR >= 7
      StimulusReflex::Installer.add_gem "redis-session-store@~> 0.11.5"
    else
      StimulusReflex::Installer.add_gem "redis-session-store@0.11.4"
    end
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
  StimulusReflex::Installer.development_working_path.write lines.join
  say "✅ Using redis-session-store for session storage"
end

# switch to redis for caching if using memory store, otherwise nudge with a comment
lines = StimulusReflex::Installer.development_working_path.readlines

if (index = lines.index { |line| line =~ /^[^#]*config.cache_store = :memory_store/ })
  lines[index] = <<~RUBY
    config.cache_store = :redis_cache_store, {
      url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" }
    }
  RUBY
  StimulusReflex::Installer.development_working_path.write lines.join
  say "✅ Using Redis for caching"
elsif lines.index { |line| line =~ /^[^#]*config.cache_store = :redis_cache_store/ }
  say "⏩ Already using Redis for caching. Skipping."
else
  if !lines.index { |line| line.include?("We couldn't identify your cache store") }
    lines.insert StimulusReflex::Installer.find_index(lines), <<~RUBY

      # We couldn't identify your cache store, but recommend using Redis:

      # config.cache_store = :redis_cache_store, {
      #   url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" }
      # }
    RUBY
    StimulusReflex::Installer.development_working_path.write lines.join
  end
  say "🤷 We couldn't identify your cache store, but recommend using Redis. See https://docs.stimulusreflex.com/appendices/deployment#use-redis-as-your-cache-store"
end

if Rails.root.join("tmp", "caching-dev.txt").exist?
  say "⏩ Already caching in development. Skipping."
else
  system "rails dev:cache"
  say "✅ Enabled caching in development"
end

StimulusReflex::Installer.complete_step :development
