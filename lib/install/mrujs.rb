entrypoint = File.read("tmp/stimulus_reflex_installer/entrypoint")
config_path = Rails.root.join(entrypoint, "config")
mrujs_path = config_path.join("mrujs.js")

pack_path = [
  Rails.root.join(entrypoint, "application.js"),
  Rails.root.join(entrypoint, "packs/application.js"),
  Rails.root.join(entrypoint, "entrypoints/application.js")
].find { |path| File.exist?(path) }

# don't proceed unless application pack exists
if pack_path.nil?
  say "❌ #{pack_path} is missing", :red
  create_file "tmp/stimulus_reflex_installer/halt", verbose: false
  return
end

# don't proceed unless config folder exists
if config_path.nil?
  say "❌ #{config_path} is missing", :red
  create_file "tmp/stimulus_reflex_installer/halt", verbose: false
  return
end

proceed = true
if !File.exist?(mrujs_path)
  options_path = Rails.root.join("tmp/stimulus_reflex_installer/options")
  options = YAML.safe_load(File.read(options_path))

  proceed = if options.key? "mrujs"
    options["mrujs"]
  else
    !no?("Would you like to install and enable mrujs? It's a modern, drop-in replacement for ujs-rails \n... and it just happens to integrate beautifully with CableReady. (Y/n)")
  end
end

if proceed
  footgun = File.read("tmp/stimulus_reflex_installer/footgun")

  if footgun == "importmap"
    importmap_path = Rails.root.join("config/importmap.rb")
    friendly_importmap_path = importmap_path.relative_path_from(Rails.root).to_s

    if !importmap_path.exist?
      say "❌ #{friendly_importmap_path} is missing. You need a valid importmap config file to proceed.", :red
      create_file "tmp/stimulus_reflex_installer/halt", verbose: false
      return
    end

    importmap = File.read(importmap_path)

    if !importmap.include?("pin \"mrujs\"")
      append_file(importmap_path, <<~RUBY)
        pin "mrujs", to: "https://ga.jspm.io/npm:mrujs@0.10.1/dist/index.module.js"
      RUBY
    end

    if !importmap.include?("pin \"mrujs\/plugins\"")
      append_file(importmap_path, <<~RUBY)
        pin "mrujs/plugins", to: "https://ga.jspm.io/npm:mrujs@0.10.1/plugins/dist/plugins.module.js"
      RUBY
    end
  else
    # queue mrujs for installation
    if !File.read(Rails.root.join("package.json")).include?('"mrujs":')
      package_list = Rails.root.join("tmp/stimulus_reflex_installer/npm_package_list")
      FileUtils.touch(package_list)
      append_file(package_list, "mrujs@^0.10.1\n", verbose: false)
      say "✅ Enqueued mrujs@^0.10.1 to be added to dependencies"
    end

    # queue @rails/ujs for removal
    if File.read(Rails.root.join("package.json")).include?('"@rails/ujs":')
      drop_package_list = Rails.root.join("tmp/stimulus_reflex_installer/drop_npm_package_list")
      FileUtils.touch(drop_package_list)
      append_file(drop_package_list, "@rails/ujs\n", verbose: false)
      say "✅ Enqueued @rails/ujs to be removed from dependencies"
    end
  end

  templates_path = File.expand_path("../generators/stimulus_reflex/templates/app/javascript/config", File.join(File.dirname(__FILE__)))
  mrujs_src = templates_path + "/mrujs.js.tt"

  # create entrypoint/config/mrujs.js if necessary
  copy_file(mrujs_src, mrujs_path) unless File.exist?(mrujs_path)

  # import mrujs config in entrypoint/config/index.js
  index_path = config_path.join("index.js")
  index = File.read(index_path)
  friendly_index_path = index_path.relative_path_from(Rails.root).to_s
  mrujs_pattern = /import ['"].\/mrujs['"]/
  mrujs_import = "import '.\/mrujs'\n"

  if !index.match?(mrujs_pattern)
    append_file(index_path, mrujs_import, verbose: false)
  end
  say "✅ mrujs imported in #{friendly_index_path}"

  # remove @rails/ujs from application.js
  friendly_pack_path = pack_path.relative_path_from(Rails.root).to_s
  rails_ujs_pattern = /import Rails from ['"]@rails\/ujs['"]/

  lines = File.readlines(pack_path)
  if lines.index { |line| line =~ rails_ujs_pattern }
    gsub_file pack_path, rails_ujs_pattern, "", verbose: false
    say "✅ @rails/ujs removed from #{friendly_pack_path}"
  end

  # remove turbolinks from Gemfile because it's incompatible with mrujs (and unnecessary)
  gemfile = Rails.root.join("Gemfile")
  turbolinks_pattern = /^[^#]*gem ["']turbolinks["']/

  lines = File.readlines(gemfile)
  if lines.index { |line| line =~ turbolinks_pattern }
    remove_gem_list = Rails.root.join("tmp/stimulus_reflex_installer/remove_gem_list")
    FileUtils.touch(remove_gem_list)
    append_file(remove_gem_list, "turbolinks\n", verbose: false)
    say "✅ Removed turbolinks from Gemfile, since it's incompatible with mrujs"
  else
    say "✅ turbolinks is not present in Gemfile"
  end
end

create_file "tmp/stimulus_reflex_installer/mrujs", verbose: false
