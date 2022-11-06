# include CableReady::Broadcaster in channels, controllers, jobs, models

channel_path = "app/channels/application_cable/channel.rb"
if Rails.root.join(channel_path).exist?
  lines = File.readlines(channel_path)
  if !lines.index { |line| line =~ /^\s*include CableReady::Broadcaster/ }
    index = lines.index { |line| line.include?("class Channel < ActionCable::Channel::Base") }
    lines.insert index + 1, "    include CableReady::Broadcaster\n"
    File.write(channel_path, lines.join)
  end
  puts "✅ include CableReady::Broadcaster in Action Cable channels"
end

controller_path = "app/controllers/application_controller.rb"
if Rails.root.join(controller_path).exist?
  lines = File.readlines(controller_path)
  if !lines.index { |line| line =~ /^\s*include CableReady::Broadcaster/ }
    index = lines.index { |line| line.include?("class ApplicationController < ActionController::Base") }
    lines.insert index + 1, "  include CableReady::Broadcaster\n"
    File.write(controller_path, lines.join)
  end
  puts "✅ include CableReady::Broadcaster in Action Controller classes"
end

if defined?(ActiveJob)
  job_path = "app/jobs/application_job.rb"
  if Rails.root.join(job_path).exist?
    lines = File.readlines(job_path)
    if !lines.index { |line| line =~ /^\s*include CableReady::Broadcaster/ }
      index = lines.index { |line| line.include?("class ApplicationJob < ActiveJob::Base") }
      lines.insert index + 1, "  include CableReady::Broadcaster\n"
      File.write(job_path, lines.join)
    end
    puts "✅ include CableReady::Broadcaster in Active Job classes"
  end
else
  puts "❔ Active Job not available. Skipping."
end

model_path = "app/models/application_record.rb"
if Rails.root.join(model_path).exist?
  lines = File.readlines(model_path)
  if !lines.index { |line| line =~ /^\s*include CableReady::Broadcaster/ }
    index = lines.index { |line| line.include?("class ApplicationRecord < ActiveRecord::Base") }
    lines.insert index + 1, "  include CableReady::Broadcaster\n"
    File.write(model_path, lines.join)
  end
  puts "✅ include CableReady::Broadcaster in Active Record model classes"
end

create_file "tmp/stimulus_reflex_installer/broadcaster", verbose: false
