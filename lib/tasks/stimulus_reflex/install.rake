# frozen_string_literal: true

require "fileutils"
require "stimulus_reflex/version"

namespace :stimulus_reflex do
  desc "Install StimulusReflex in this application"
  task install: :environment do
    system "rails dev:cache" unless Rails.root.join("tmp", "caching-dev.txt").exist?
    gem_version = StimulusReflex::VERSION.gsub(".pre", "-pre")
    system "yarn add stimulus_reflex@#{gem_version}"
    system "bundle exec rails webpacker:install:stimulus"
    main_folder = defined?(Webpacker) ? Webpacker.config.source_path.to_s.gsub("#{Rails.root}/", "") : "app/javascript"

    FileUtils.mkdir_p Rails.root.join("#{main_folder}/controllers"), verbose: true
    FileUtils.mkdir_p Rails.root.join("app/reflexes"), verbose: true

    filepath = [
      "#{main_folder}/controllers/index.js",
      "#{main_folder}/controllers/index.ts",
      "#{main_folder}/packs/application.js",
      "#{main_folder}/packs/application.ts"
    ]
      .select { |path| File.exist?(path) }
      .map { |path| Rails.root.join(path) }
      .first

    puts "Updating #{filepath}"
    lines = File.open(filepath, "r") { |f| f.readlines }

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
    lines << "StimulusReflex.initialize(application, { consumer, controller, isolate: true })\n" unless initialize_line
    lines << "StimulusReflex.debug = process.env.RAILS_ENV === 'development'\n" unless initialize_line
    File.open(filepath, "w") { |f| f.write lines.join }

    filepath = Rails.root.join("config/environments/development.rb")
    lines = File.open(filepath, "r") { |f| f.readlines }
    unless lines.find { |line| line.include?("config.session_store") }
      lines.insert 3, "  config.session_store :cache_store\n\n"
      File.open(filepath, "w") { |f| f.write lines.join }
    end

    filepath = Rails.root.join("config/cable.yml")
    lines = File.open(filepath, "r") { |f| f.readlines }
    if lines[1].include?("adapter: async")
      lines.delete_at 1
      lines.insert 1, "  adapter: redis\n"
      lines.insert 2, "  url: <%= ENV.fetch(\"REDIS_URL\") { \"redis://localhost:6379/1\" } %>\n"
      lines.insert 3, "  channel_prefix: " + File.basename(Rails.root.to_s).underscore + "_development\n"
      File.open(filepath, "w") { |f| f.write lines.join }
    end

    system "bundle exec rails generate stimulus_reflex example"
    puts "Generating default StimulusReflex configuration file into your application config/initializers directory"
    system "bundle exec rails generate stimulus_reflex:config"

    puts
    puts "StimulusReflex and CableReady have been successfully installed!"
    puts "Go to https://docs.stimulusreflex.com/quickstart if you need help getting started."
    puts
  end
end
