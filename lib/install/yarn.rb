# run yarn install only when packages are waiting to be added or removed
package_list = Rails.root.join("tmp/stimulus_reflex_installer/npm_package_list")
dev_package_list = Rails.root.join("tmp/stimulus_reflex_installer/npm_dev_package_list")
drop_package_list = Rails.root.join("tmp/stimulus_reflex_installer/drop_npm_package_list")

package_json = JSON.parse(Rails.root.join("package.json"))

add = File.readlines(package_list).map(&:chomp)
dev = File.readlines(dev_package_list).map(&:chomp)
drop = File.readlines(drop_package_list).map(&:chomp)

if add.present? || dev.present? || drop.present?

  add.each do |package|
    matches = package.match(/(.+)@(.+)/)
    name, version = matches[1], matches[2]
    package_json["dependencies"][name] = version
  end

  dev.each do |package|
    matches = package.match(/(.+)@(.+)/)
    name, version = matches[1], matches[2]
    package_json["devDependencies"][name] = version
  end

  drop.each do |package|
    package_json["dependencies"].delete(package)
    package_json["devDependencies"].delete(package)
  end

  File.write(Rails.root.join("package.json"), JSON.pretty_generate(package_json))

  system "yarn install"

end

create_file "tmp/stimulus_reflex_installer/yarn", verbose: false
