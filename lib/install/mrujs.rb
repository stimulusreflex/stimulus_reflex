entrypoint = File.read("tmp/stimulus_reflex_installer/entrypoint")
config_path = Rails.root.join(entrypoint, "config")
mrujs_path = config_path.join("mrujs.js")

proceed = true
if !File.exist?(mrujs_path)
  proceed = !no?("Would you like to install and enable mrujs? It's a modern, drop-in replacement for ujs-rails \n... and it just happens to integrate beautifully with CableReady. (Y/n)")
end

if proceed
  footgun = File.read("tmp/stimulus_reflex_installer/footgun")

  if footgun == "importmap"
    # pin "mrujs", to: "https://ga.jspm.io/npm:mrujs@0.10.1/dist/index.module.js"
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

  pack_path = [
    Rails.root.join(entrypoint, "application.js"),
    Rails.root.join(entrypoint, "packs/application.js")
  ].find { |path| File.exist?(path) }

  # don't proceed unless application pack exists
  if pack_path.nil?
    say "❌ #{pack_path} is missing", :red
    create_file "tmp/stimulus_reflex_installer/halt", verbose: false
    return
  end

  empty_directory config_path unless config_path.exist?

  # create entrypoint/config/mrujs.js
  copy_file(mrujs_src, mrujs_path) unless File.exist?(mrujs_path)

  # import mrujs in application.js
  pack = File.read(pack_path)
  friendly_path = pack_path.relative_path_from(Rails.root).to_s
  mrujs_pattern = /import ['"].\/config\/mrujs['"]/
  mrujs_commented_pattern = /\s*\/\/\s*#{mrujs_pattern}/
  mrujs_import = {
    "webpacker" => "import \"config\/mrujs\"\n",
    "esbuild" => "import \".\/config\/mrujs\"\n",
    "importmap" => "import \"config\/mrujs\"\n"
  }

  if pack.match?(mrujs_pattern)
    if pack.match?(mrujs_commented_pattern)
      if !no?("mrujs seems to be commented out in your application.js. Do you want to enable it? (Y/n)")
        # uncomment_lines only works with Ruby comments 🙄
        lines = File.readlines(pack_path)
        matches = lines.select { |line| line =~ mrujs_commented_pattern }
        lines[lines.index(matches.last).to_i] = mrujs_import[footgun]
        File.write(pack_path, lines.join)
        say "✅ mrujs imported in #{friendly_path}"
      else
        say "❔ mrujs is not being imported in your application.js. We trust that you have a reason for this."
      end
    else
      say "✅ mrujs imported in #{friendly_path}"
    end
  else
    lines = File.readlines(pack_path)
    matches = lines.select { |line| line =~ /^import / }
    lines.insert lines.index(matches.last).to_i + 1, mrujs_import[footgun]
    File.write(pack_path, lines.join)
    say "✅ mrujs imported in #{friendly_path}"
  end

  # remove @rails/ujs from application.js
  rails_ujs_pattern = /import Rails from ['"]@rails\/ujs['"]/

  lines = File.readlines(pack_path)
  if lines.index { |line| line =~ rails_ujs_pattern }
    gsub_file pack_path, rails_ujs_pattern, "", verbose: false
    say "✅ @rails/ujs removed from #{friendly_path}"
  end

  # remove turbolinks from Gemfile because it's incompatible with mrujs (and unnecessary)
  gemfile = Rails.root.join("Gemfile")
  turbolinks_pattern = /^[^#]*gem ["']turbolinks["']/

  lines = File.readlines(gemfile)
  if (index = lines.index { |line| line =~ turbolinks_pattern })
    lines[index] = "# #{lines[index]}"
    File.write(gemfile, lines.join)
    say "✅ Removed turbolinks from Gemfile, since it's incompatible with mrujs"
  else
    say "✅ turbolinks is not present in Gemfile"
  end
end

create_file "tmp/stimulus_reflex_installer/mrujs", verbose: false
