# frozen_string_literal: true

namespace :stimulus_reflex do
  desc "Verifies StimulusReflex is installed"
  task :check_stimulus_reflex do
    stimulus_reflex_info = `yarn info stimulus_reflex`
    raise Errno::ENOENT if stimulus_reflex_info.blank?
  rescue Errno::ENOENT
    warn "StimulusReflex is not installed! Please run `yarn add stimulus_reflex`"
    warn "Exiting!" && exit!
  end
end
