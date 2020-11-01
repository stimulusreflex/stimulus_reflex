# frozen_string_literal: true

StimulusReflex.configure do |config|
  # Enable/disable whether startup should be aborted when the sanity checks fail
  # config.exit_on_failed_sanity_checks = true

  # Override the parent class that the StimulusReflex ActionCable channel inherits from
  # config.parent_channel = "ApplicationCable::Channel"
end
