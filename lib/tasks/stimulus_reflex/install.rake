# frozen_string_literal: true

require "fileutils"

namespace :stimulus_reflex do
  desc "Install StimulusReflex in this application"
  task install: :environment do
    system "bundle exec rails webpacker:install:stimulus"
    system "yarn add stimulus_reflex"

    FileUtils.mkdir_p Rails.root.join("app/javascript/controllers"), verbose: true
    FileUtils.mkdir_p Rails.root.join("app/reflexes"), verbose: true

    filepath = Rails.root.join("app/javascript/controllers/index.js")
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

    system "bundle exec rails generate stimulus_reflex example"
  end
end
