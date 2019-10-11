bin_path = ENV["BUNDLE_BIN"] || "./bin"

namespace :stimulus_reflex do
  desc "Install StimulusReflex in this application"
  task install: [:check_yarn, :check_stimulus_reflex] do
    exec "#{RbConfig.ruby} #{bin_path}/rails generate stimulus_reflex example"
  end
end
