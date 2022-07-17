# frozen_string_literal: true

require "fileutils"
require "stimulus_reflex/version"
require "stimulus_reflex/installer_helper"

namespace :stimulus_reflex do
  desc "Install StimulusReflex in this application"

  task :install do
    if type = StimulusReflex::InstallerHelper.type
      Rake::Task["stimulus_reflex:install:#{type}"].invoke
    else
      puts "Couldn't detect your JavaScript setup."
      puts
      puts "Run either:"
      puts "  rails stimulus_reflex:install:webpack"
      puts "  rails stimulus_reflex:install:esbuild"
      puts
      puts "or"
      puts
      puts "  rails stimulus_reflex:install:importmaps"
    end
  end

  namespace :install do
    def javascript_path
      StimulusReflex::InstallerHelper.javascript_path
    end

    def run_cache
      system "rails dev:cache" unless Rails.root.join("tmp", "caching-dev.txt").exist?
    end

    def common_install
      FileUtils.mkdir_p Rails.root.join("#{javascript_path}/controllers"), verbose: true
      FileUtils.mkdir_p Rails.root.join("#{javascript_path}/config"), verbose: true
      FileUtils.mkdir_p Rails.root.join("app/reflexes"), verbose: true

      system "rails g channel example"

      puts
      puts "✨ Updating config/environments/development.rb"
      filepath = Rails.root.join("config/environments/development.rb")
      lines = File.readlines(filepath)
      unless lines.find { |line| line.include?("config.session_store") }
        matches = lines.select { |line| line =~ /\A(Rails.application.configure do)/ }
        lines.insert lines.index(matches.last).to_i + 1, "  config.session_store :cache_store\n\n"
        puts
        puts "✨ Using :cache_store for session storage. We recommend switching to Redis for cache and session storage."
        puts
        puts "https://docs.stimulusreflex.com/appendices/deployment#use-redis-as-your-cache-store"
        File.write(filepath, lines.join)
      end

      if defined?(ActionMailer)
        lines = File.readlines(filepath)
        unless lines.find { |line| line.include?("config.action_mailer.default_url_options") }
          matches = lines.select { |line| line =~ /\A(Rails.application.configure do)/ }
          lines.insert lines.index(matches.last).to_i + 1, "  config.action_mailer.default_url_options = {host: \"localhost\", port: 3000}\n\n"
          File.write(filepath, lines.join)
        end
      end

      lines = File.readlines(filepath)
      unless lines.find { |line| line.include?("config.action_controller.default_url_options") }
        matches = lines.select { |line| line =~ /\A(Rails.application.configure do)/ }
        lines.insert lines.index(matches.last).to_i + 1, "  config.action_controller.default_url_options = {host: \"localhost\", port: 3000}\n"
        File.write(filepath, lines.join)
      end

      puts
      puts "✨ Updating config/cable.yml to use Redis in development"
      filepath = Rails.root.join("config/cable.yml")
      lines = File.readlines(filepath)
      if lines[1].include?("adapter: async")
        lines.delete_at 1
        lines.insert 1, "  adapter: redis\n"
        lines.insert 2, "  url: <%= ENV.fetch(\"REDIS_URL\") { \"redis://localhost:6379/1\" } %>\n"
        lines.insert 3, "  channel_prefix: " + File.basename(Rails.root.to_s).tr("\\", "").tr("-. ", "_").underscore + "_development\n"
        File.write(filepath, lines.join)
      end

      puts
      puts "✨ Generating default StimulusReflex and CableReady configuration files"
      puts

      system "bundle exec rails generate stimulus_reflex:initializer"
      system "bundle exec rails generate stimulus_reflex:config"

      system "bundle exec rails generate cable_ready:initializer"
      system "bundle exec rails generate cable_ready:config"

      puts
      puts "✨ Generating ApplicationReflex class and Stimulus controllers, plus an example Reflex class and controller"
      puts
      system "bundle exec rails generate stimulus_reflex example"

      puts
      puts "🎉 StimulusReflex and CableReady have been successfully installed! 🎉"
      puts
      puts "https://docs.stimulusreflex.com/hello-world/quickstart"
      puts
      puts "😊 The fastest way to get support is to say hello on Discord:"
      puts
      puts "https://discord.gg/stimulus-reflex"
      puts
    end

    desc "Alias for stimulus_reflex:install:importmaps"
    task :importmap => :importmaps

    desc "Install StimulusReflex via Importmaps in this application"
    task importmaps: :environment do
      run_cache
      system "bin/importmap pin stimulus_reflex@#{StimulusReflex::InstallerHelper.stimulus_reflex_gem_version}"
      common_install
    end

    desc "Install StimulusReflex via esbuild in this application"
    task esbuild: :environment do
      run_cache

      packages = [
        "@rails/actioncable",
        "stimulus_reflex@#{StimulusReflex::InstallerHelper.stimulus_reflex_gem_version}",
        "cable_ready@#{StimulusReflex::InstallerHelper.cable_ready_gem_version}",
        "esbuild-rails"
      ]

      system "yarn add #{packages.join(" ")}"

      common_install
    end

    desc "Alias for stimulus_reflex:install:webpack"
    task :node => :webpack

    desc "Alias for stimulus_reflex:install:webpack"
    task :webpacker => :webpack

    desc "Install StimulusReflex via Webpacker in this application"
    task webpack: :environment do
      run_cache

      packages = [
        "@rails/actioncable",
        "stimulus_reflex@#{StimulusReflex::InstallerHelper.stimulus_reflex_gem_version}",
        "cable_ready@#{StimulusReflex::InstallerHelper.cable_ready_gem_version}",
        "@hotwired/stimulus-webpack-helpers"
      ]

      system "yarn add #{packages.join(" ")}"

      system "bundle exec rails webpacker:install:stimulus"

      filepath = [
        "#{javascript_path}/controllers/index.js",
        "#{javascript_path}/controllers/index.ts",
        "#{javascript_path}/packs/application.js",
        "#{javascript_path}/packs/application.ts"
      ]
        .select { |path| File.exist?(path) }
        .map { |path| Rails.root.join(path) }
        .first

      puts "✨ Updating #{filepath}"
      lines = File.readlines(filepath)

      unless lines.find { |line| line.start_with?("import StimulusReflex") }
        matches = lines.select { |line| line =~ /\A(require|import)/ }
        lines.insert lines.index(matches.last).to_i + 1, "import StimulusReflex from 'stimulus_reflex'\n"
      end

      unless lines.find { |line| line.start_with?("import consumer") }
        matches = lines.select { |line| line =~ /\A(require|import)/ }
        lines.insert lines.index(matches.last).to_i + 1, "import consumer from '../channels/consumer'\n"
      end

      unless lines.find { |line| line.start_with?("import controller") }
        matches = lines.select { |line| line =~ /\A(require|import)/ }
        lines.insert lines.index(matches.last).to_i + 1, "import controller from '../controllers/application_controller'\n"
      end

      initialize_line = lines.find { |line| line.start_with?("StimulusReflex.initialize") }
      lines << "application.consumer = consumer\n"
      lines << "StimulusReflex.initialize(application, { controller, isolate: true })\n" unless initialize_line
      lines << "StimulusReflex.debug = process.env.RAILS_ENV === 'development'\n" unless initialize_line
      File.write(filepath, lines.join)

      common_install
    end

  end
end
