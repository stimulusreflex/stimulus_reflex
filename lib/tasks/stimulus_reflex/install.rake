# frozen_string_literal: true

require "fileutils"
require "stimulus_reflex/version"

namespace :stimulus_reflex do
  desc "Install StimulusReflex in this application"
  task install: :environment do
    system "bundle exec rails webpacker:install:stimulus"
    gem_version = StimulusReflex::VERSION.gsub(".pre", "-pre")
    system "yarn add stimulus_reflex@#{gem_version}"

    FileUtils.mkdir_p Rails.root.join("app/javascript/controllers"), verbose: true
    FileUtils.mkdir_p Rails.root.join("app/reflexes"), verbose: true

    filepath = %w[
      app/javascript/controllers/index.js
      app/javascript/controllers/index.ts
      app/javascript/packs/application.js
      app/javascript/packs/application.ts
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
      lines.insert lines.index(matches.last).to_i + 1, "import controller from './application_controller'\n"
    end

    initialize_line = lines.find { |line| line.start_with?("StimulusReflex.initialize") }
    lines << "StimulusReflex.initialize(application, { consumer, controller, debug: false })\n" unless initialize_line
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
      lines.insert 3, "  channel_prefix: " + Rails.application.class.module_parent.to_s.underscore + "_development\n"
      File.open(filepath, "w") { |f| f.write lines.join }
    end

    system "bundle exec rails generate stimulus_reflex example"
    system "rails dev:cache" unless Rails.root.join("tmp", "caching-dev.txt").exist?
  end
end
