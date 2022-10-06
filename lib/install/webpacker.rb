entrypoint = File.read("tmp/stimulus_reflex_installer/entrypoint")
pack_path = Rails.root.join(entrypoint, "packs/application.js")
friendly_pack_path = pack_path.relative_path_from(Rails.root).to_s

if !pack_path.exist?
  say "❌ #{friendly_pack_path} is missing. You need a valid application pack file to proceed.", :red
  create_file "tmp/stimulus_reflex_installer/halt", verbose: false
  return
end

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

controllers_path = Rails.root.join(entrypoint, "controllers")
controller_templates_path = File.expand_path("../generators/stimulus_reflex/templates/app/javascript/controllers", File.join(File.dirname(__FILE__)))
application_controller_src = controller_templates_path + "/application_controller.js.tt"
application_controller_path = controllers_path.join("application_controller.js")
application_src = controller_templates_path + "/application.js.tt"
application_path = controllers_path.join("application.js")
index_src = controller_templates_path + "/index.js.webpacker.tt"
index_path = controllers_path.join("index.js")

# create entrypoint/controllers, as well as the index, application and application_controller
empty_directory controllers_path unless controllers_path.exist?

copy_file(application_controller_src, application_controller_path) unless application_controller_path.exist?
# webpacker 5.4 did not colloquially feature a controllers/application.js file
copy_file(application_src, application_path) unless application_path.exist?
copy_file(index_src, index_path) unless index_path.exist?

pack = File.read(pack_path)
controllers_pattern = /import ['"]controllers['"]/
controllers_commented_pattern = /\s*\/\/\s*#{controllers_pattern}/

if pack.match?(controllers_pattern)
  if pack.match?(controllers_commented_pattern)
    if !no?("Do you want to import your Stimulus controllers in application.js? (Y/n)")
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
add_gem_list = Rails.root.join("tmp/stimulus_reflex_installer/add_gem_list")
FileUtils.touch(add_gem_list)
append_file(add_gem_list, "webpacker@5.4.3\n", verbose: false)
say "✅ Enqueued webpacker 5.4.3 to be added to the Gemfile"

create_file "tmp/stimulus_reflex_installer/webpacker", verbose: false
