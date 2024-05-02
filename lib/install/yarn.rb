# frozen_string_literal: true

require "stimulus_reflex/installer"

if !StimulusReflex::Installer.package_json_path.exist?
  say "⏩ No package.json file found. Skipping."

  return
end

# run yarn install only when packages are waiting to be added or removed
add = StimulusReflex::Installer.package_list.exist? ? StimulusReflex::Installer.package_list.readlines.map(&:chomp) : []
dev = StimulusReflex::Installer.dev_package_list.exist? ? StimulusReflex::Installer.dev_package_list.readlines.map(&:chomp) : []
drop = StimulusReflex::Installer.drop_package_list.exist? ? StimulusReflex::Installer.drop_package_list.readlines.map(&:chomp) : []

json = JSON.parse(StimulusReflex::Installer.package_json_path.read)

if add.present? || dev.present? || drop.present?

  add.each do |package|
    matches = package.match(/(.+)@(.+)/)
    name, version = matches[1], matches[2]
    json["dependencies"] = {} unless json["dependencies"]
    json["dependencies"][name] = version
  end

  dev.each do |package|
    matches = package.match(/(.+)@(.+)/)
    name, version = matches[1], matches[2]
    json["devDependencies"] = {} unless json["devDependencies"]
    json["devDependencies"][name] = version
  end

  drop.each do |package|
    json["dependencies"].delete(package)
    json["devDependencies"].delete(package)
  end

  StimulusReflex::Installer.package_json_path.write JSON.pretty_generate(json)

  system "yarn install --silent"
else
  say "⏩ No yarn depdencies to add or remove. Skipping."
end

if StimulusReflex::Installer.bundler == "esbuild" && json["scripts"]["build"] != "node esbuild.config.mjs"
  json["scripts"]["build:default"] = json["scripts"]["build"]
  json["scripts"]["build"] = "node esbuild.config.mjs"
  StimulusReflex::Installer.package_json_path.write JSON.pretty_generate(json)
  say "✅ Your yarn build script has been updated to use esbuild.config.mjs"
else
  say "⏩ Your yarn build script is already setup. Skipping."
end

StimulusReflex::Installer.complete_step :yarn
