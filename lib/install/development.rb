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
gemfile = Rails.root.join("Gemfile")
lines = File.readlines(development)
redis_session_store_pattern = /gem ['"]redis-session-store['"]/

if (index = lines.index { |line| line =~ /^[^#]*config.session_store/ })  
  if !/^[^#]*redis_session_store/.match?(lines[index])
    # add redis-session-store to Gemfile, but comment it out
    if !File.read(gemfile).match?(redis_session_store_pattern)
      FileUtils.touch(add_gem_list)
      add_gem_list = Rails.root.join("tmp/stimulus_reflex_installer/add_gem_list")
      append_file(add_gem_list, "# redis-session-store@0.11.4\n", verbose: false)
      say "✅ Enqueued redis-session-store 0.11.4 to be added to the Gemfile, but commented out"
    end
  end
else
  redis_pattern = /gem ['"]redis['"]/
  add_gem_list = Rails.root.join("tmp/stimulus_reflex_installer/add_gem_list")
  remove_gem_list = Rails.root.join("tmp/stimulus_reflex_installer/remove_gem_list")
  
  # add redis v4 to be compatible with redis-session-store
  if File.read(gemfile).match?(redis_pattern)
    FileUtils.touch(remove_gem_list)
    append_file(remove_gem_list, "redis\n", verbose: false)
    FileUtils.touch(add_gem_list)
    append_file(add_gem_list, "redis@>= 4\", \"< 5\n", verbose: false)
    say "✅ Enqueued redis to be added to the Gemfile"
  end

  # add redis-session-store to Gemfile
  if !File.read(gemfile).match?(redis_session_store_pattern)
    FileUtils.touch(add_gem_list)
    append_file(add_gem_list, "redis-session-store@0.11.4\n", verbose: false)
    say "✅ Enqueued redis-session-store 0.11.4 to be added to the Gemfile"
  end
end

# Enable caching in development
if !Rails.root.join("tmp/caching-dev.txt").exist?
  system "rails dev:cache"
  puts
end

create_file "tmp/stimulus_reflex_installer/development", verbose: false
