# frozen_string_literal: true

StimulusReflex.configure do |config|
  # Enable/disable exiting / warning when the sanity checks fail options:
  # `:exit` or `:warn` or `:ignore`
  # config.on_failed_sanity_checks = :exit

  # Override the parent class that the StimulusReflex ActionCable channel inherits from
  # config.parent_channel = "ApplicationCable::Channel"

  # Print colorized Reflex log messages
  # Available tokens are :session_id, :session_id_full, :reflex_info, :operation, :reflex_id, :reflex_id_full :mode, :selector, :operation_counter, :connection_id, :connection_id_full, :timestamp
  # Available colors are :red, :green, :yellow, :blue, :magenta, :cyan, :white
  # You can also use attributes from your ActionCable Connection's identifiers that resolve to valid ActiveRecord models
  # eg. if your connection is `identified_by :current_user` and your User model has an :email attribute, you can pass :email ... it will display `-` if the user isn't logged in

  config.logging = [:timestamp, :red, " [", :session_id, "] ", :magenta, :operation_counter, " ", :green, :reflex_info, " -> ", :white, :selector, " ", :yellow, :operation, :white, " via ", :blue, :mode, " Morph", :cyan, " to ", :connection_id]
end
