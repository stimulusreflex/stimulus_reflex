# frozen_string_literal: true

require "stimulus_reflex/installer"

return if StimulusReflex::Installer.pack_path_missing?

mrujs_path = StimulusReflex::Installer.config_path / "mrujs.js"

proceed = false

if !File.exist?(mrujs_path)
  proceed = if StimulusReflex::Installer.options.key? "mrujs"
    StimulusReflex::Installer.options["mrujs"]
  else
    !no?("✨ Would you like to install and enable mrujs? It's a modern, drop-in replacement for rails-ujs (Y/n)")
  end
end

if proceed
  if StimulusReflex::Installer.bundler.importmap?

    if !StimulusReflex::Installer.importmap_path.exist?
      StimulusReflex::Installer.halt "#{friendly_StimulusReflex::Installer.importmap_path} is missing. You need a valid importmap config file to proceed."
      return
    end

    importmap = StimulusReflex::Installer.importmap_path.read

    if importmap.include?("pin \"mrujs\"")
      say "⏩ mrujs already pinned. Skipping."
    else
      append_file(StimulusReflex::Installer.importmap_path, <<~RUBY, verbose: false)
        pin "mrujs", to: "https://ga.jspm.io/npm:mrujs@0.10.1/dist/index.module.js"
      RUBY
      say "✅ pin mrujs"
    end

    if importmap.include?("pin \"mrujs/plugins\"")
      say "⏩ mrujs/plugins already pinned. Skipping."
    else
      append_file(StimulusReflex::Installer.importmap_path, <<~RUBY, verbose: false)
        pin "mrujs/plugins", to: "https://ga.jspm.io/npm:mrujs@0.10.1/plugins/dist/plugins.module.js"
      RUBY
      say "✅ pin mrujs/plugins"
    end
  else
    # queue mrujs for installation
    if StimulusReflex::Installer.package_json_path.read.include?('"mrujs":')
      say "⏩ mrujs already present. Skipping."
    else
      StimulusReflex::Installer.add_package "mrujs@^0.10.1"
    end

    # queue @rails/ujs for removal
    if StimulusReflex::Installer.package_json_path.read.include?('"@rails/ujs":')
      StimulusReflex::Installer.drop_package "@rails/ujs"
    else
      say "⏩ @rails/ujs not present. Skipping."
    end
  end

  step_path = "/app/javascript/config/"
  mrujs_src = StimulusReflex::Installer.fetch(step_path, "mrujs.js.tt")

  # create entrypoint/config/mrujs.js if necessary
  copy_file(mrujs_src, mrujs_path) unless mrujs_path.exist?

  # import mrujs config in entrypoint/config/index.js
  index_path = StimulusReflex::Installer.config_path / "index.js"
  index = index_path.read
  friendly_index_path = index_path.relative_path_from(Rails.root).to_s
  mrujs_pattern = /import ['"].\/mrujs['"]/

  mrujs_import = if StimulusReflex::Installer.bundler.importmap?
    %(import "config/mrujs"\n)
  else
    %(import "./mrujs"\n)
  end

  if index.match?(mrujs_pattern)
    say "⏩ mrujs already imported in #{friendly_index_path}. Skipping."
  else
    append_file(index_path, mrujs_import, verbose: false)
    say "✅ mrujs imported in #{friendly_index_path}"
  end

  # remove @rails/ujs from application.js
  rails_ujs_pattern = /import Rails from ['"]@rails\/ujs['"]/

  lines = StimulusReflex::Installer.pack_path.readlines
  if lines.index { |line| line =~ rails_ujs_pattern }
    gsub_file StimulusReflex::Installer.pack_path, rails_ujs_pattern, "", verbose: false
    say "✅ @rails/ujs removed from #{StimulusReflex::Installer.friendly_pack_path}"
  else
    say "⏩ @rails/ujs not present in #{StimulusReflex::Installer.friendly_pack_path}. Skipping."
  end

  # set Action View to generate remote forms when using form_with
  application_path = Rails.root.join("config/application.rb")
  application_pattern = /^[^#]*config\.action_view\.form_with_generates_remote_forms = true/
  defaults_pattern = /config\.load_defaults \d\.\d/

  lines = application_path.readlines
  StimulusReflex::Installer.backup(application_path) do
    if !lines.index { |line| line =~ application_pattern }
      if (index = lines.index { |line| line =~ /^[^#]*#{defaults_pattern}/ })
        gsub_file application_path, /\s*#{defaults_pattern}\n/, verbose: false do
          <<-RUBY
  \n#{lines[index]}
      # form_with helper will generate remote forms by default (mrujs)
      config.action_view.form_with_generates_remote_forms = true
          RUBY
        end
      else
        insert_into_file application_path, after: "class Application < Rails::Application" do
          <<-RUBY

      # form_with helper will generate remote forms by default (mrujs)
      config.action_view.form_with_generates_remote_forms = true
          RUBY
        end
      end
    end
    say "✅ form_with_generates_remote_forms set to true in config/application.rb"
  end

  # remove turbolinks from Gemfile because it's incompatible with mrujs (and unnecessary)
  turbolinks_pattern = /^[^#]*gem ["']turbolinks["']/

  lines = StimulusReflex::Installer.gemfile_path.readlines
  if lines.index { |line| line =~ turbolinks_pattern }
    StimulusReflex::Installer.remove_gem :turbolinks
  else
    say "⏩ turbolinks is not present in Gemfile. Skipping."
  end
end

StimulusReflex::Installer.complete_step :mrujs
