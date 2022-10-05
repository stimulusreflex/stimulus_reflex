entrypoint = File.read("tmp/stimulus_reflex_installer/entrypoint")
pack_path = Rails.root.join(entrypoint, "application.js")
friendly_pack_path = pack_path.relative_path_from(Rails.root).to_s

if !pack_path.exist?
  say "❌ #{friendly_pack_path} is missing. You need a valid application pack file to proceed.", :red
  create_file "tmp/stimulus_reflex_installer/halt", verbose: false
  return
end

# verify that all critical dependencies are up to date; if not, queue for later
package_list = Rails.root.join("tmp/stimulus_reflex_installer/npm_package_list")
package_json = Rails.root.join("package.json")
lines = File.readlines(package_json)

if !lines.index { |line| line =~ /^\s*["']esbuild-rails["']: ["']\^1.0.3["']/ }
  FileUtils.touch(package_list)
  append_file(package_list, "esbuild-rails@^1.0.3\n", verbose: false)
  say "✅ Enqueued esbuild-rails@^1.0.3 to be added to dependencies"
end

if !lines.index { |line| line =~ /^\s*["']@hotwired\/stimulus["']: ["']\^3.1.0["']/ }
  FileUtils.touch(package_list)
  append_file(package_list, "@hotwired/stimulus@^3.1.0\n", verbose: false)
  say "✅ Enqueued @hotwired/stimulus@^3.1.0 to be added to dependencies"
end

# copy esbuild.config.js to app root
esbuild_src = File.expand_path("../generators/stimulus_reflex/templates/esbuild.config.js.tt", File.join(File.dirname(__FILE__)))
esbuild_path = Rails.root.join("esbuild.config.js")
if esbuild_path.exist?
  if File.read(esbuild_path) == File.read(esbuild_src)
    say "✅ esbuild.config.js present in app root"
  else
    copy_file(esbuild_path, "#{esbuild_path}.bak", verbose: false)
    remove_file(esbuild_path, verbose: false)
    copy_file(esbuild_src, esbuild_path, verbose: false)
    append_file("tmp/stimulus_reflex_installer/backups", "esbuild.config.js\n", verbose: false)
    say "✅ esbuild.config.js copied to app root"
    say "❕ original esbuild.config.js renamed esbuild.config.js.bak", :green
  end
else
  copy_file(esbuild_src, esbuild_path)
end

controllers_path = Rails.root.join(entrypoint, "controllers")
templates_path = File.expand_path("../generators/stimulus_reflex/templates/app/javascript/controllers", File.join(File.dirname(__FILE__)))
application_controller_src = templates_path + "/application_controller.js.tt"
application_controller_path = controllers_path.join("application_controller.js")
application_src = templates_path + "/application.js.tt"
application_path = controllers_path.join("application.js")
index_src = templates_path + "/index.js.esbuild.tt"
index_path = controllers_path.join("index.js")

# create entrypoint/controllers, if necessary
empty_directory controllers_path unless controllers_path.exist?

# copy application_controller.js, if necessary
copy_file(application_controller_src, application_controller_path) unless application_controller_path.exist?

# configure Stimulus application superclass to import Action Cable consumer
friendly_application_path = application_path.relative_path_from(Rails.root).to_s
if application_path.exist?
  if File.read(application_path).include?("import consumer")
    say "✅ #{friendly_application_path} is present"
  else
    inject_into_file application_path, "import consumer from \"../channels/consumer\"\n", after: "import { Application } from \"@hotwired/stimulus\"\n", verbose: false
    inject_into_file application_path, "application.consumer = consumer\n", after: "application.debug = false\n", verbose: false
    say "#{friendly_application_path} has been updated to import the Action Cable consumer"
  end
else
  copy_file(application_src, application_path)
end

friendly_index_path = index_path.relative_path_from(Rails.root).to_s
if index_path.exist?
  if File.read(index_path) == File.read(index_src)
    say "✅ #{friendly_index_path} is present"
  else
    copy_file(index_path, "#{index_path}.bak", verbose: false)
    remove_file(index_path, verbose: false)
    copy_file(index_src, index_path, verbose: false)
    append_file("tmp/stimulus_reflex_installer/backups", "#{friendly_index_path}\n", verbose: false)
    say "#{friendly_index_path} has been created"
    say "❕ original index.js renamed index.js.bak", :green
  end
else
  copy_file(index_src, index_path)
end

pack = File.read(pack_path)
controllers_pattern = /import ['"].\/controllers['"]/
controllers_commented_pattern = /\s*\/\/\s*#{controllers_pattern}/

if pack.match?(controllers_pattern)
  if pack.match?(controllers_commented_pattern)
    if !no?("Stimulus seems to be commented out in your application.js. Do you want to import your controllers? (Y/n)")
      # uncomment_lines only works with Ruby comments 🙄
      lines = File.readlines(pack_path)
      matches = lines.select { |line| line =~ controllers_commented_pattern }
      lines[lines.index(matches.last).to_i] = "import \".\/controllers\"\n"
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
  lines.insert lines.index(matches.last).to_i + 1, "import \".\/controllers\"\n"
  File.write(pack_path, lines.join)
  say "✅ Stimulus controllers imported in #{friendly_pack_path}"
end

create_file "tmp/stimulus_reflex_installer/esbuild_rails", verbose: false
