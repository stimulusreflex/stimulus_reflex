# frozen_string_literal: true

module StimulusReflex
  class VersionMismatchError < StandardError
  end

  module VersionChecker
    def check_version!
      return if StimulusReflex.config.on_failed_sanity_checks == :ignore
      return if version == StimulusReflex::VERSION

      level = (StimulusReflex.config.on_failed_sanity_checks == :exit) ? "error" : "warn"
      reason = (level == "error") ? "failed to execute your reflex action due to" : "noticed"

      mismatch = "StimulusReflex #{reason} a version mismatch between your gem and JavaScript version. Package versions must match exactly.\n\nstimulus_reflex gem: #{StimulusReflex::VERSION}\nstimulus_reflex npm: #{npm_version}"

      StimulusReflex.config.logger.error("\n\e[31m#{mismatch}\e[0m")

      log = {
        message: mismatch,
        level: level,
        reflexId: id
      }

      event = {
        name: "stimulus-reflex:version-mismatch",
        reflexId: id,
        detail: {
          message: mismatch,
          gem: StimulusReflex::VERSION,
          npm: npm_version,
          level: level
        }
      }

      toast = {
        text: mismatch.to_s,
        destination: "https://docs.stimulusreflex.com/hello-world/setup#upgrading-package-versions-and-sanity",
        reflexId: id,
        level: level
      }

      CableReady::Channels.instance[@channel.stream_name].tap { |channel|
        channel.console_log(log)
        channel.dispatch_event(event)
        channel.stimulus_reflex_version_mismatch(toast) if Rails.env.development?
      }.broadcast

      return if level == "warn"

      raise VersionMismatchError.new(mismatch)
    end
  end
end
