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
    import_line = lines.find { |line| line.start_with?("import StimulusReflex") }
    initialize_line = lines.find { |line| line.start_with?("StimulusReflex.initialize") }
    unless import_line
      matches = lines.select { |line| line =~ /\A(require|import)/ }
      lines.insert lines.index(matches.last).to_i + 1, "import StimulusReflex from 'stimulus_reflex'\n"
    end
    lines << "StimulusReflex.initialize(application)\n" unless initialize_line
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
