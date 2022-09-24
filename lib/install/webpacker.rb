# verify that all critical dependencies are up to date; if not, queue for later
package_list = Rails.root.join("tmp/stimulus_reflex_installer/npm_package_list")
dev_package_list = Rails.root.join("tmp/stimulus_reflex_installer/npm_dev_package_list")
package_json = Rails.root.join("package.json")
lines = File.readlines(package_json)

if !lines.index { |line| line =~ /^\s*["']webpack["']: ["']\^4.46.0["']/ }
  FileUtils.touch(package_list)
  append_file(package_list, "webpack@^4.46.0\n", verbose: false)
  say "✅ Enqueued webpack@^4.46.0 to be added to dependencies"
end

if !lines.index { |line| line =~ /^\s*["']webpack-cli["']: ["']\^3.3.12["']/ }
  FileUtils.touch(package_list)
  append_file(package_list, "webpack-cli@^3.3.12\n", verbose: false)
  say "✅ Enqueued webpack-cli@^3.3.12 to be added to dependencies"
end

if !lines.index { |line| line =~ /^\s*["']@rails\/webpacker["']: ["']\^5.4.3["']/ }
  FileUtils.touch(package_list)
  append_file(package_list, "@rails/webpacker@^5.4.3\n", verbose: false)
  say "✅ Enqueued @rails/webpacker@^5.4.3 to be added to dependencies"
end

if !lines.index { |line| line =~ /^\s*["']@hotwired\/stimulus["']: ["']\^3.1.0["']/ }
  FileUtils.touch(package_list)
  append_file(package_list, "@hotwired/stimulus@^3.1.0\n", verbose: false)
  say "✅ Enqueued @hotwired/stimulus@^3.1.0 to be added to dependencies"
end

if !lines.index { |line| line =~ /^\s*["']@hotwired\/stimulus-webpack-helpers["']: ["']\^1.0.1["']/ }
  FileUtils.touch(package_list)
  append_file(package_list, "@hotwired/stimulus-webpack-helpers@^1.0.1\n", verbose: false)
  say "✅ Enqueued @hotwired/stimulus-webpack-helpers@^1.0.1 to be added to dependencies"
end

if !lines.index { |line| line =~ /^\s*["']webpack-dev-server["']: ["']\^3.11.3["']/ }
  FileUtils.touch(dev_package_list)
  append_file(dev_package_list, "webpack-dev-server@^3.11.3\n", verbose: false)
  say "✅ Enqueued webpack-dev-server@^3.11.3 to be added to dev dependencies"
end

entrypoint = File.read("tmp/stimulus_reflex_installer/entrypoint")
controllers_path = Rails.root.join(entrypoint, "controllers")
controller_templates_path = File.expand_path("../generators/stimulus_reflex/templates/app/javascript/controllers", File.join(File.dirname(__FILE__)))
application_controller_src = controller_templates_path + "/application_controller.js.tt"
application_controller_path = controllers_path.join("application_controller.js")
application_src = controller_templates_path + "/application.js.tt"
application_path = controllers_path.join("application.js")
index_src = controller_templates_path + "/index_webpacker.js.tt"
index_path = controllers_path.join("index.js")

# create js frontend entrypoint if it doesn't already exist
if !Rails.root.join(entrypoint).exist?
  FileUtils.mkdir_p(Rails.root.join(entrypoint))
  puts "✅ Created #{entrypoint}"
end

# create entrypoint/controllers, as well as the index, application and application_controller
empty_directory controllers_path unless controllers_path.exist?

copy_file(application_controller_src, application_controller_path) unless application_controller_path.exist?
copy_file(application_src, application_path) unless application_path.exist?
copy_file(index_src, index_path) unless index_path.exist?

pack_path = Rails.root.join(entrypoint, "packs/application.js")
pack_templates_path = File.expand_path("../generators/stimulus_reflex/templates/app/javascript/packs", File.join(File.dirname(__FILE__)))
pack_src = pack_templates_path + "/application.js.tt"
friendly_pack_path = pack_path.relative_path_from(Rails.root).to_s

if pack_path.exist?
  if File.read(pack_path) == File.read(pack_src)
    say "✅ #{pack_path} is present"
  else
    copy_file(pack_path, "#{pack_path}.bak", verbose: false)
    remove_file(pack_path, verbose: false)
    copy_file(pack_src, pack_path, verbose: false)
    append_file("tmp/stimulus_reflex_installer/backups", "#{friendly_pack_path}\n")
    say "#{friendly_pack_path} has been created"
    say "❕ original application.js renamed application.js.bak", :green
  end
else
  copy_file(pack_src, pack_path)
end

pack = File.read(pack_path)
controllers_pattern = /import ['"]controllers['"]/
controllers_commented_pattern = /\s*\/\/\s*#{controllers_pattern}/

if pack.match?(controllers_pattern)
  if pack.match?(controllers_commented_pattern)
    if !no?("Stimulus seems to be commented out in your application.js. Do you want to import your controllers? (Y/n)")
      # uncomment_lines only works with Ruby comments 🙄
      lines = File.readlines(pack_path)
      matches = lines.select { |line| line =~ controllers_commented_pattern }
      lines[lines.index(matches.last).to_i] = "import \"controllers\"\n"
      File.write(pack_path, lines.join)
      say "✅ Stimulus controllers imported in #{friendly_pack_path}"
    else
      say "❔ your Stimulus controllers are not being imported in your application.js. We trust that you have a reason for this."
    end
  else
    say "✅ Stimulus controllers imported in #{friendly_pack_path}"
  end
else
  lines = File.readlines(pack_path)
  matches = lines.select { |line| line =~ /^import / }
  lines.insert lines.index(matches.last).to_i + 1, "import \"controllers\"\n"
  File.write(pack_path, lines.join)
  say "✅ Stimulus controllers imported in #{friendly_pack_path}"
end

# ensure webpacker 5.4.3 is installed in the Gemfile
gemfile = Rails.root.join("Gemfile")
lines = File.readlines(gemfile)
index = lines.index { |line| line =~ /gem ['"]webpacker['"]/ }
if index
  if !lines[index].match(/^[^#]*gem ['"]webpacker['"].*5.4.3['"]/)
    lines[index] = "gem \"webpacker\", \"~> 5.4.3\"\n"
    File.write(gemfile, lines.join)
  end
else
  append_file gemfile, "\n# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker"
  gem "webpacker", "~> 5.4.3"
end
say "✅ webpacker gem is installed and up to date"

create_file "tmp/stimulus_reflex_installer/webpacker", verbose: false
