require "stimulus_reflex/version"
require "cable_ready/version"

sr_npm_version = StimulusReflex::VERSION.gsub(".pre", "-pre")
cr_npm_version = CableReady::VERSION.gsub(".pre", "-pre")
package_list = Rails.root.join("tmp/stimulus_reflex_installer/npm_package_list")
package_json = Rails.root.join("package.json")
lines = File.readlines(package_json)

if !lines.index { |line| line =~ /^\s*["']cable_ready["']: ["'].*#{cr_npm_version}["']/ }
  FileUtils.touch(package_list)
  append_file(package_list, "cable_ready@#{cr_npm_version}\n")
  say "✅ Enqueued cable_ready@#{cr_npm_version} to be added to dependencies"
end

if !lines.index { |line| line =~ /^\s*["']stimulus_reflex["']: ["'].*#{sr_npm_version}["']/ }
  FileUtils.touch(package_list)
  append_file(package_list, "stimulus_reflex@#{sr_npm_version}\n")
  say "✅ Enqueued stimulus_reflex@#{sr_npm_version} to be added to dependencies"
end

create_file "tmp/stimulus_reflex_installer/npm_packages", verbose: false
