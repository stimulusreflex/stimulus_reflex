# frozen_string_literal: true

StimulusReflex.configure do |config|
  # Enable/disable exiting / warning when the sanity checks fail options:
  # `:exit` or `:warn` or `:ignore`
  # config.on_failed_sanity_checks = :exit

  # Override the parent class that the StimulusReflex ActionCable channel inherits from
  # config.parent_channel = "ApplicationCable::Channel"
end
