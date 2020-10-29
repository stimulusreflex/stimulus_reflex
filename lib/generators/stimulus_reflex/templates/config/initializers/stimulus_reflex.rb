# frozen_string_literal: true

StimulusReflex.configure do |config|
  # Enable/disable whether startup should be aborted
  # when the sanity checks fail.
  config.exit_on_failed_sanity_checks = true
end
