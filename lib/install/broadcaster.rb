# frozen_string_literal: true

require "stimulus_reflex/installer"

def needs_broadcaster?(path)
  return false unless path.exist?

  !path.readlines.index { |line| line =~ /^\s*include CableReady::Broadcaster/ }
end

channel_path = Rails.root.join("app/channels/application_cable/channel.rb")
controller_path = Rails.root.join("app/controllers/application_controller.rb")
job_path = Rails.root.join("app/jobs/application_job.rb")
model_path = Rails.root.join(StimulusReflex::Installer.application_record_path)

include_in_channel = needs_broadcaster?(channel_path)
include_in_controller = needs_broadcaster?(controller_path)
include_in_job = needs_broadcaster?(job_path)
include_in_model = needs_broadcaster?(model_path)

proceed = [include_in_channel, include_in_controller, include_in_job, include_in_model].reduce(:|)

unless proceed
  StimulusReflex::Installer.complete_step :broadcaster

  puts "⏩ CableReady::Broadcaster already included in all files. Skipping."
  return
end

proceed = if StimulusReflex::Installer.options.key? "broadcaster"
  StimulusReflex::Installer.options["broadcaster"]
else
  !no?("✨ Make CableReady::Broadcaster available to channels, controllers, jobs and models? (Y/n)")
end

unless proceed
  StimulusReflex::Installer.complete_step :broadcaster

  puts "⏩ Skipping."
  return
end

broadcaster_include = "\n    include CableReady::Broadcaster\n"

# include CableReady::Broadcaster in Action Cable Channel classes
if include_in_channel
  StimulusReflex::Installer.backup(channel_path) do
    inject_into_file channel_path, broadcaster_include, after: /class (ApplicationCable::)?Channel < ActionCable::Channel::Base/, verbose: false
  end

  puts "✅ include CableReady::Broadcaster in ApplicationCable::Channel"
else
  puts "⏩ Not including CableReady::Broadcaster in ApplicationCable::Channel channels. Skipping."
end

# include CableReady::Broadcaster in Action Controller classes
if include_in_controller
  StimulusReflex::Installer.backup(controller_path) do
    inject_into_class controller_path, "ApplicationController", broadcaster_include, verbose: false
  end

  puts "✅ include CableReady::Broadcaster in ApplicationController"
else
  puts "⏩ Not including CableReady::Broadcaster in ApplicationController. Skipping."
end

# include CableReady::Broadcaster in Active Job classes, if present

if include_in_job
  StimulusReflex::Installer.backup(job_path) do
    inject_into_class job_path, "ApplicationJob", broadcaster_include, verbose: false
  end

  puts "✅ include CableReady::Broadcaster in ApplicationJob"
else
  puts "⏩ Not including CableReady::Broadcaster in ApplicationJob. Skipping."
end

# include CableReady::Broadcaster in Active Record model classes
if include_in_model
  StimulusReflex::Installer.backup(StimulusReflex::Installer.application_record_path) do
    inject_into_class StimulusReflex::Installer.application_record_path, "ApplicationRecord", broadcaster_include, verbose: false
  end

  puts "✅ include CableReady::Broadcaster in ApplicationRecord"
else
  puts "⏩ Not including CableReady::Broadcaster in ApplicationRecord. Skipping"
end

StimulusReflex::Installer.complete_step :broadcaster
