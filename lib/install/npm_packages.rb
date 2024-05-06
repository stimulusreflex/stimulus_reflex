# frozen_string_literal: true

require "stimulus_reflex/installer"

lines = StimulusReflex::Installer.package_json_path.readlines

if !lines.index { |line| line =~ /^\s*["']cable_ready["']: ["'].*#{StimulusReflex::Installer.cr_npm_version}["']/ }
  StimulusReflex::Installer.add_package "cable_ready@#{StimulusReflex::Installer.cr_npm_version}"
else
  say "⏩ cable_ready npm package is already present. Skipping."
end

if !lines.index { |line| line =~ /^\s*["']stimulus_reflex["']: ["'].*#{StimulusReflex::Installer.sr_npm_version}["']/ }
  StimulusReflex::Installer.add_package "stimulus_reflex@#{StimulusReflex::Installer.sr_npm_version}"
else
  say "⏩ stimulus_reflex npm package is already present. Skipping."
end

if !lines.index { |line| line =~ /^\s*["']@hotwired\/stimulus["']:/ }
  StimulusReflex::Installer.add_package "@hotwired/stimulus@^3.2"
else
  say "⏩ @hotwired/stimulus npm package is already present. Skipping."
end

StimulusReflex::Installer.complete_step :npm_packages
