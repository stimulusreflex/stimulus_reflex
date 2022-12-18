require "stimulus_reflex/installer"

return if pack_path_missing?

# verify that all critical dependencies are up to date; if not, queue for later
lines = package_json.readlines

if !lines.index { |line| line =~ /^\s*["']esbuild-rails["']: ["']\^1.0.3["']/ }
  add_package "esbuild-rails@^1.0.3"
end

if !lines.index { |line| line =~ /^\s*["']@hotwired\/stimulus["']:/ }
  add_package "@hotwired/stimulus@^3.2"
end
# copy esbuild.config.js to app root
esbuild_src = fetch(File.expand_path(template_src + "/esbuild.config.js.tt", File.join(File.dirname(__FILE__))))
esbuild_path = Rails.root.join("esbuild.config.js")
if esbuild_path.exist?
  if esbuild_path.read == esbuild_src.read
    say "✅ esbuild.config.js present in app root"
  else
    backup(esbuild_path) do
      template(esbuild_src, esbuild_path, verbose: false, entrypoint: entrypoint)
    end
  end
else
  template(esbuild_src, esbuild_path, entrypoint: entrypoint)
end

templates_path = File.expand_path(template_src + "/app/javascript/controllers", File.join(File.dirname(__FILE__)))
application_controller_src = fetch(templates_path + "/application_controller.js.tt")
application_controller_path = controllers_path / "application_controller.js"
application_js_src = fetch(templates_path + "/application.js.tt")
application_js_path = controllers_path / "application.js"
index_src = fetch(templates_path + "/index.js.esbuild.tt")
index_path = controllers_path / "index.js"
friendly_index_path = index_path.relative_path_from(Rails.root).to_s

# create entrypoint/controllers, if necessary
empty_directory controllers_path unless controllers_path.exist?

# copy application_controller.js, if necessary
copy_file(application_controller_src, application_controller_path) unless application_controller_path.exist?

# configure Stimulus application superclass to import Action Cable consumer
friendly_application_js_path = application_js_path.relative_path_from(Rails.root).to_s
if application_js_path.exist?
  backup(application_js_path) do
    if application_js_path.read.include?("import consumer")
      say "✅ #{friendly_application_js_path} is present"
    else
      inject_into_file application_js_path, "import consumer from \"../channels/consumer\"\n", after: "import { Application } from \"@hotwired/stimulus\"\n", verbose: false
      inject_into_file application_js_path, "application.consumer = consumer\n", after: "application.debug = false\n", verbose: false
      say "#{friendly_application_js_path} has been updated to import the Action Cable consumer"
    end
  end
else
  copy_file(application_js_src, application_js_path)
end

if index_path.exist?
  if index_path.read != index_src.read
    backup(index_path, delete: true) do
      copy_file(index_src, index_path, verbose: false)
    end
  end
else
  copy_file(index_src, index_path)
end
say "#{friendly_index_path} has been created"

controllers_pattern = /import ['"].\/controllers['"]/
controllers_commented_pattern = /\s*\/\/\s*#{controllers_pattern}/

if pack.match?(controllers_pattern)
  if pack.match?(controllers_commented_pattern)
    proceed = if options.key? "uncomment"
      options["uncomment"]
    else
      !no?("Stimulus seems to be commented out in your application.js. Do you want to import your controllers? (Y/n)")
    end

    if proceed
      # uncomment_lines only works with Ruby comments 🙄
      lines = pack_path.readlines
      matches = lines.select { |line| line =~ controllers_commented_pattern }
      lines[lines.index(matches.last).to_i] = "import \".\/controllers\"\n"
      pack_path.write lines.join
      say "✅ Stimulus controllers imported in #{friendly_pack_path}"
    else
      say "🤷 your Stimulus controllers are not being imported in your application.js. We trust that you have a reason for this."
    end
  else
    say "✅ Stimulus controllers imported in #{friendly_pack_path}"
  end
else
  lines = pack_path.readlines
  matches = lines.select { |line| line =~ /^import / }
  lines.insert lines.index(matches.last).to_i + 1, "import \".\/controllers\"\n"
  pack_path.write lines.join
  say "✅ Stimulus controllers imported in #{friendly_pack_path}"
end

complete_step :esbuild
