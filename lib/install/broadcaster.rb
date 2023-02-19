# frozen_string_literal: true

require "stimulus_reflex/installer"

def needs_broadcaster?(path)
  return false unless path.exist?

  !path.readlines.index { |line| line =~ /^\s*include CableReady::Broadcaster/ }
end

channel_path = Rails.root.join("app/channels/application_cable/channel.rb")
controller_path = Rails.root.join("app/controllers/application_controller.rb")
job_path = Rails.root.join("app/jobs/application_job.rb")
model_path = Rails.root.join(application_record_path)

include_in_channel = needs_broadcaster?(channel_path)
include_in_controller = needs_broadcaster?(controller_path)
include_in_job = needs_broadcaster?(job_path)
include_in_model = needs_broadcaster?(model_path)

proceed = [include_in_channel, include_in_controller, include_in_job, include_in_model].reduce(:|)

unless proceed
  complete_step :broadcaster

  puts "⏩ CableReady::Broadcaster already included in all files. Skipping."
  return
end

proceed = if options.key? "broadcaster"
  options["broadcaster"]
else
  !no?("✨ Make CableReady::Broadcaster available to channels, controllers, jobs and models? (Y/n)")
end

unless proceed
  complete_step :broadcaster

  puts "⏩ Skipping."
  return
end

# include CableReady::Broadcaster in Action Cable Channel classes
if include_in_channel
  backup(channel_path) do
    lines = channel_path.readlines
    index = lines.index { |line| line.include?("class Channel < ActionCable::Channel::Base") }
    lines.insert index + 1, "    include CableReady::Broadcaster\n"
    channel_path.write lines.join
  end

  puts "✅ include CableReady::Broadcaster in ApplicationCable::Channel"
else
  puts "⏩ already included CableReady::Broadcaster in ApplicationCable::Channel channels. Skipping."
end

# include CableReady::Broadcaster in Action Controller classes
if include_in_controller
  backup(controller_path) do
    lines = controller_path.readlines
    index = lines.index { |line| line.include?("") }
    lines.insert index + 1, "    include CableReady::Broadcaster\n"
    controller_path.write lines.join
  end

  puts "✅ include CableReady::Broadcaster in ApplicationController"
else
  puts "⏩ already included CableReady::Broadcaster in ApplicationController. Skipping."
end

# include CableReady::Broadcaster in Active Job classes, if present

if include_in_job
  backup(job_path) do
    lines = job_path.readlines
    index = lines.index { |line| line.include?("class ApplicationJob < ActiveJob::Base") }
    lines.insert index + 1, "  include CableReady::Broadcaster\n"
    job_path.write lines.join
  end

  puts "✅ include CableReady::Broadcaster in ApplicationJob"
else
  puts "⏩ already included CableReady::Broadcaster in ApplicationJob. Skipping."
end

# include CableReady::Broadcaster in Active Record model classes
if include_in_model
  backup(application_record_path) do
    lines = application_record_path.readlines
    index = lines.index { |line| line.include?("class ApplicationRecord < ActiveRecord::Base") }
    lines.insert index + 1, "  include CableReady::Broadcaster\n"
    application_record_path.write lines.join
  end

  puts "✅ include CableReady::Broadcaster in ApplicationRecord"
else
  puts "⏩ already included CableReady::Broadcaster in ApplicationRecord. Skipping"
end

complete_step :broadcaster
