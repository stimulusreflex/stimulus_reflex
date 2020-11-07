# frozen_string_literal: true

StimulusReflex.configure do |config|
  # Enable/disable whether startup should be aborted when the sanity checks fail
  # config.exit_on_failed_sanity_checks = true

  # Override the parent class that the StimulusReflex ActionCable channel inherits from
	# config.parent_channel = "ApplicationCable::Channel"

	# Opt in/out of printing verbose ActionCable log messages
	# config.debug = false

	# Print colorized reflex log message including: session_id, reflex_name, broadcaster, selector, connection_id, timestamp.
	# Use available colors: black, red, green, yellow, blue, magenta, cyan, white.
	# config.logging = [
	# 	'red',
	# 	'[',
	# 	:session_id,
	# 	'] ',
	# 	'green',
	# 	:reflex_name,
	# 	'yellow',
	# 	' on (',
	# 	:broadcaster,
	# 	': #',
	# 	:selector,
	# 	') ',
	# 	'cyan',
	# 	'for ',
	# 	:connection_id,
	# 	'magenta',
	# 	' at ',
	# 	:timestamp
	# ]
end
