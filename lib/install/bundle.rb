# frozen_string_literal: true

require "stimulus_reflex/installer"

hash = StimulusReflex::Installer.gemfile_hash

# run bundle only when gems are waiting to be added or removed
add = StimulusReflex::Installer.add_gem_list.exist? ? StimulusReflex::Installer.add_gem_list.readlines.map(&:chomp) : []
remove = StimulusReflex::Installer.remove_gem_list.exist? ? StimulusReflex::Installer.remove_gem_list.readlines.map(&:chomp) : []

if add.present? || remove.present?
  lines = StimulusReflex::Installer.gemfile_path.readlines

  remove.each do |name|
    index = lines.index { |line| line =~ /gem ['"]#{name}['"]/ }
    if index
      if /^[^#]*gem ['"]#{name}['"]/.match?(lines[index])
        lines[index] = "# #{lines[index]}"
        say "✅ #{name} gem has been disabled"
      else
        say "⏩ #{name} gem is already disabled. Skipping."
      end
    end
  end

  add.each do |package|
    matches = package.match(/(.+)@(.+)/)
    name, version = matches[1], matches[2]

    index = lines.index { |line| line =~ /gem ['"]#{name}['"]/ }
    if index
      if !lines[index].match(/^[^#]*gem ['"]#{name}['"].*#{version}['"]/)
        lines[index] = "\ngem \"#{name}\", \"#{version}\"\n"
        say "✅ #{name} gem has been installed"
      else
        say "⏩ #{name} gem is already installed. Skipping."
      end
    else
      lines << "\ngem \"#{name}\", \"#{version}\"\n"
    end
  end

  StimulusReflex::Installer.gemfile_path.write lines.join

  bundle_command("install --quiet", "BUNDLE_IGNORE_MESSAGES" => "1") if hash != StimulusReflex::Installer.gemfile_hash
else
  say "⏩ No rubygems depedencies to install. Skipping."
end

FileUtils.cp(StimulusReflex::Installer.development_working_path, StimulusReflex::Installer.development_path)
say "✅ development environment configuration installed"

FileUtils.cp(StimulusReflex::Installer.action_cable_initializer_working_path, StimulusReflex::Installer.action_cable_initializer_path)
say "✅ Action Cable initializer installed"

StimulusReflex::Installer.complete_step :bundle
