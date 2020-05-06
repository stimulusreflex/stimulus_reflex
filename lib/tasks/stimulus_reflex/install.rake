# frozen_string_literal: true

require "fileutils"

namespace :stimulus_reflex do
  desc "Install StimulusReflex in this application"
  task install: :environment do
    system "bundle exec rails webpacker:install:stimulus"
    system "yarn add stimulus_reflex"

    FileUtils.mkdir_p Rails.root.join("app/javascript/controllers"), verbose: true
    FileUtils.mkdir_p Rails.root.join("app/reflexes"), verbose: true

    filepath = if File.exist? Rails.root.join("app/javascript/controllers/index.js")
      Rails.root.join("app/javascript/controllers/index.js")
    else
      Rails.root.join("app/javascript/packs/application.js")
    end
    puts "Updating #{filepath}"
    lines = File.open(filepath, "r") { |f| f.readlines }

    import_stimulus_refelx_line = lines.find { |line| line.start_with?("import StimulusReflex") }
    unless import_stimulus_refelx_line
      matches = lines.select { |line| line =~ /\A(require|import)/ }
      lines.insert lines.index(matches.last).to_i + 1, "import StimulusReflex from 'stimulus_reflex'\n"
    end

    import_consumer_line = lines.find { |line| line.start_with?("import consumer") }
    unless import_consumer_line
      matches = lines.select { |line| line =~ /\A(require|import)/ }
      lines.insert lines.index(matches.last).to_i + 1, "import consumer from '../channels/consumer'\n"
    end

    import_controller_line = lines.find { |line| line.start_with?("import controller") }
    unless import_controller_line
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

    system "bundle exec rails generate stimulus_reflex example"
    system "rails dev:cache" unless Rails.root.join("tmp", "caching-dev.txt").exist?
  end
end
