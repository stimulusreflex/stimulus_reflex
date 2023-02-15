# frozen_string_literal: true

require "stimulus_reflex/installer"

lines = package_json.readlines

if !lines.index { |line| line =~ /^\s*["']cable_ready["']: ["'].*#{cr_npm_version}["']/ }
  add_package "cable_ready@#{cr_npm_version}"
else
  say "⏩ cable_ready npm package is already present. Skipping."
end

if !lines.index { |line| line =~ /^\s*["']stimulus_reflex["']: ["'].*#{sr_npm_version}["']/ }
  add_package "stimulus_reflex@#{sr_npm_version}"
else
  say "⏩ stimulus_reflex npm package is already present. Skipping."
end

complete_step :npm_packages
