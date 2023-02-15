# frozen_string_literal: true

require "stimulus_reflex/installer"

# include CableReady::Broadcaster in Action Cable Channel classes
channel_path = Rails.root.join("app/channels/application_cable/channel.rb")
if channel_path.exist?
  lines = channel_path.readlines
  if !lines.index { |line| line =~ /^\s*include CableReady::Broadcaster/ }
    backup(channel_path) do
      index = lines.index { |line| line.include?("class Channel < ActionCable::Channel::Base") }
      lines.insert index + 1, "    include CableReady::Broadcaster\n"
      channel_path.write lines.join
    end
  end
  puts "✅ include CableReady::Broadcaster in Action Cable channels"
end

# include CR::B in Action Controller classes
controller_path = Rails.root.join("app/controllers/application_controller.rb")
if controller_path.exist?
  lines = controller_path.readlines
  if !lines.index { |line| line =~ /^\s*include CableReady::Broadcaster/ }
    backup(controller_path) do
      index = lines.index { |line| line.include?("class ApplicationController < ActionController::Base") }
      lines.insert index + 1, "  include CableReady::Broadcaster\n"
      controller_path.write lines.join
    end
  end
  puts "✅ include CableReady::Broadcaster in Action Controller classes"
end

# include CR::B in Active Job classes, if present
if defined?(ActiveJob)
  job_path = Rails.root.join("app/jobs/application_job.rb")
  if job_path.exist?
    lines = job_path.readlines
    if !lines.index { |line| line =~ /^\s*include CableReady::Broadcaster/ }
      backup(job_path) do
        index = lines.index { |line| line.include?("class ApplicationJob < ActiveJob::Base") }
        lines.insert index + 1, "  include CableReady::Broadcaster\n"
        job_path.write lines.join
      end
    end
    puts "✅ include CableReady::Broadcaster in Active Job classes"
  end
else
  puts "🤷 Active Job not available. Skipping."
end

# include CR::B in StateMachines, if present
if defined?(StateMachines)
  lines = action_cable_initializer_working_path.read
  if !lines.include?("StateMachines::Machine.prepend(CableReady::Broadcaster)")
    inject_into_file action_cable_initializer_working_path, after: "CableReady.configure do |config|\n", verbose: false do
      <<-RUBY

  StateMachines::Machine.prepend(CableReady::Broadcaster)

      RUBY
    end
  end
  puts "✅ prepend CableReady::Broadcaster into StateMachines::Machine"
else
  puts "🤷 StateMachines not available. Skipping."
end

# include CR::B in Active Record model classes
if Rails.root.join(application_record_path).exist?
  lines = application_record_path.readlines
  if !lines.index { |line| line =~ /^\s*include CableReady::Broadcaster/ }
    backup(application_record_path) do
      index = lines.index { |line| line.include?("class ApplicationRecord < ActiveRecord::Base") }
      lines.insert index + 1, "  include CableReady::Broadcaster\n"
      application_record_path.write lines.join
    end
  end
  puts "✅ include CableReady::Broadcaster in Active Record model classes"
end

complete_step :broadcaster
