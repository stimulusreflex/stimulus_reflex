# frozen_string_literal: true

require "stimulus_reflex/installer"

if application_record_path.exist?
  lines = application_record_path.readlines

  if !lines.index { |line| line =~ /^\s*include CableReady::Updatable/ }
    proceed = if options.key? "updatable"
      options["updatable"]
    else
      !no?("✨ Include CableReady::Updatable in Active Record model classes? (Y/n)")
    end

    unless proceed
      complete_step :updatable

      puts "⏩ Skipping."
      return
    end

    index = lines.index { |line| line.include?("class ApplicationRecord < ActiveRecord::Base") }
    lines.insert index + 1, "  include CableReady::Updatable\n"
    application_record_path.write lines.join

    say "✅ included CableReady::Updatable in ApplicationRecord"
  else
    say "⏩ CableReady::Updatable has already been included in Active Record model classes. Skipping."
  end
else
  say "⏩ ApplicationRecord doesn't exist. Skipping."
end

complete_step :updatable
