# frozen_string_literal: true

require "stimulus_reflex/installer"

hash = gemfile_hash

# run bundle only when gems are waiting to be added or removed
add = add_gem_list.exist? ? add_gem_list.readlines.map(&:chomp) : []
remove = remove_gem_list.exist? ? remove_gem_list.readlines.map(&:chomp) : []

if add.present? || remove.present?
  lines = gemfile_path.readlines

  remove.each do |name|
    index = lines.index { |line| line =~ /gem ['"]#{name}['"]/ }
    if index
      if /^[^#]*gem ['"]#{name}['"]/.match?(lines[index])
        lines[index] = "# #{lines[index]}"
      end
      say "✅ #{name} gem has been disabled"
    end
  end

  add.each do |package|
    matches = package.match(/(.+)@(.+)/)
    name, version = matches[1], matches[2]

    index = lines.index { |line| line =~ /gem ['"]#{name}['"]/ }
    if index
      if !lines[index].match(/^[^#]*gem ['"]#{name}['"].*#{version}['"]/)
        lines[index] = "\ngem \"#{name}\", \"#{version}\"\n"
      end
    else
      lines << "\ngem \"#{name}\", \"#{version}\"\n"
    end
    say "✅ #{name} gem has been installed"
  end

  gemfile_path.write lines.join

  bundle_command("install --quiet", "BUNDLE_IGNORE_MESSAGES" => "1") if hash != gemfile_hash
end

if application_record_path.exist?
  lines = application_record_path.readlines
  if !lines.index { |line| line =~ /^\s*include CableReady::Updatable/ }
    index = lines.index { |line| line.include?("class ApplicationRecord < ActiveRecord::Base") }
    lines.insert index + 1, "  include CableReady::Updatable\n"
    application_record_path.write lines.join
  end
  puts "✅ include CableReady::Updatable in Active Record model classes"
end

FileUtils.cp(development_working_path, development_path)
say "✅ development environment configuration installed"

FileUtils.cp(action_cable_initializer_working_path, action_cable_initializer_path)
say "✅ Action Cable initializer installed"

complete_step :bundle
