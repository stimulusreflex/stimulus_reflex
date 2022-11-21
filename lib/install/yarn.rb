# run yarn install only when packages are waiting to be added or removed
package_list = Rails.root.join("tmp/stimulus_reflex_installer/npm_package_list")
dev_package_list = Rails.root.join("tmp/stimulus_reflex_installer/npm_dev_package_list")
drop_package_list = Rails.root.join("tmp/stimulus_reflex_installer/drop_npm_package_list")

package_json = JSON.parse(File.read(Rails.root.join("package.json")))

add = package_list.exist? ? File.readlines(package_list).map(&:chomp) : []
dev = dev_package_list.exist? ? File.readlines(dev_package_list).map(&:chomp) : []
drop = drop_package_list.exist? ? File.readlines(drop_package_list).map(&:chomp) : []

if add.present? || dev.present? || drop.present?

  add.each do |package|
    matches = package.match(/(.+)@(.+)/)
    name, version = matches[1], matches[2]
    package_json["dependencies"] = {} unless package_json["dependencies"]
    package_json["dependencies"][name] = version
  end

  dev.each do |package|
    matches = package.match(/(.+)@(.+)/)
    name, version = matches[1], matches[2]
    package_json["devDependencies"] = {} unless package_json["devDependencies"]
    package_json["devDependencies"][name] = version
  end

  drop.each do |package|
    package_json["dependencies"].delete(package)
    package_json["devDependencies"].delete(package)
  end

  File.write(Rails.root.join("package.json"), JSON.pretty_generate(package_json))

  system "yarn install --silent"

end

footgun = File.read("tmp/stimulus_reflex_installer/footgun")
if footgun == "esbuild" && package_json["scripts"]["build"] != "node esbuild.config.js"
  package_json["scripts"]["build:default"] = package_json["scripts"]["build"]
  package_json["scripts"]["build"] = "node esbuild.config.js"
  File.write(Rails.root.join("package.json"), JSON.pretty_generate(package_json))
  say "✅ Your build script has been updated to use esbuild.config.js"
end

create_file "tmp/stimulus_reflex_installer/yarn", verbose: false
