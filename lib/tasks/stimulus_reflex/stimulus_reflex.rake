# frozen_string_literal: true

require "stimulus_reflex/installer"

SR_STEPS = {
  "action_cable" => "Action Cable",
  "webpacker" => "Install StimulusReflex using Webpacker",
  "shakapacker" => "Install StimulusReflex using Shakapacker",
  "npm_packages" => "StimulusReflex and CableReady and related npm packages",
  "reflexes" => "Create app/reflexes and related files",
  "importmap" => "Install StimulusReflex using importmaps",
  "esbuild" => "Install StimulusReflex using esbuild",
  "config" => "Client initialization",
  "initializers" => "StimulusReflex and CableReady initializers",
  "example" => "Create an Example Reflex",
  "development" => "development environment configuration",
  "spring" => "Disable spring gem. Spring has been removed from Rails 7",
  "mrujs" => "Swap out Rails UJS for mrujs",
  "broadcaster" => "Make CableReady available to channels, controllers, jobs and models",
  "updatable" => "Include CableReady::Updatable in Active Record model classes",
  "yarn" => "Resolve npm dependency changes",
  "bundle" => "Resolve gem dependency changes and install configuration changes",
  "vite" => "Install StimulusReflex using Vite",
  "compression" => "Compress WebSocket traffic with gzip"
}

SR_BUNDLERS = {
  "webpacker" => ["npm_packages", "webpacker", "config", "action_cable", "reflexes", "development", "initializers", "broadcaster", "updatable", "example", "spring", "yarn", "bundle"],
  "esbuild" => ["npm_packages", "esbuild", "config", "action_cable", "reflexes", "development", "initializers", "broadcaster", "updatable", "example", "spring", "yarn", "bundle"],
  "vite" => ["npm_packages", "vite", "config", "action_cable", "reflexes", "development", "initializers", "broadcaster", "updatable", "example", "spring", "yarn", "bundle"],
  "shakapacker" => ["npm_packages", "shakapacker", "config", "action_cable", "reflexes", "development", "initializers", "broadcaster", "updatable", "example", "spring", "yarn", "bundle"],
  "importmap" => ["config", "action_cable", "importmap", "reflexes", "development", "initializers", "broadcaster", "updatable", "example", "spring", "bundle"]
}

def run_install_template(template, force: false, trace: false)
  puts "--- [#{template}] ----"

  if Rails.root.join("tmp/stimulus_reflex_installer/halt").exist?
    FileUtils.rm(Rails.root.join("tmp/stimulus_reflex_installer/halt"))
    puts "StimulusReflex installation halted. Please fix the issues above and try again."
    exit
  end
  if Rails.root.join("tmp/stimulus_reflex_installer/#{template}").exist? && !force
    puts "👍 #{SR_STEPS[template]}"
    return
  end

  system "#{RbConfig.ruby} ./bin/rails app:template LOCATION=#{File.expand_path("../../install/#{template}.rb", __dir__)} SKIP_SANITY_CHECK=true #{"--trace" if trace}"

  puts
end

namespace :stimulus_reflex do
  desc "✨ Install StimulusReflex and CableReady ✨"
  task :install do
    StimulusReflex::Installer.create_dir_if_not_exists(Rails.root.join("tmp/stimulus_reflex_installer/templates"))
    StimulusReflex::Installer.create_dir_if_not_exists(Rails.root.join("tmp/stimulus_reflex_installer/working"))

    install_complete = Rails.root.join("tmp/stimulus_reflex_installer/complete")

    used_bundler = nil
    options = {}

    ARGV.each do |arg|
      # make sure we have a valid build tool specified, or proceed to automatic detection
      if ["webpacker", "esbuild", "vite", "shakapacker", "importmap"].include?(arg)
        used_bundler = arg
      else
        kv = arg.split("=")
        if kv.length == 2
          kv[1] = if kv[1] == "true"
            true
          else
            (kv[1] == "false") ? false : kv[1]
          end
          options[kv[0]] = kv[1]
        end
      end
    end

    options_path = Rails.root.join("tmp/stimulus_reflex_installer/options")
    options_path.write(options.to_yaml)

    if install_complete.exist?
      puts "✨ \e[38;5;220mStimulusReflex\e[0m and \e[38;5;220mCableReady\e[0m are already installed ✨"
      puts
      puts "To restart the installation process, run: \e[38;5;231mrails stimulus_reflex:install:restart\e[0m"
      puts
      puts "To get started, check out \e[4;97mhttps://docs.stimulusreflex.com/hello-world/quickstart\e[0m"
      puts "or get help on Discord: \e[4;97mhttps://discord.gg/stimulus-reflex\e[0m. \e[38;5;196mWe are here for you.\e[0m 💙"
      puts
      exit
    end

    # if there is an installation in progress, continue where we left off
    if StimulusReflex::Installer.installer_entrypoint_path.exist?
      entrypoint = StimulusReflex::Installer.installer_entrypoint_path.read

      puts "✨ Resuming \e[38;5;220mStimulusReflex\e[0m and \e[38;5;220mCableReady\e[0m installation ✨"
      puts
      puts "If you have any setup issues, please consult \e[4;97mhttps://docs.stimulusreflex.com/hello-world/setup\e[0m"
      puts "or get help on Discord: \e[4;97mhttps://discord.gg/stimulus-reflex\e[0m. \e[38;5;196mWe are here for you.\e[0m 💙"
      puts
      puts "Resuming installation into \e[1m#{entrypoint}\e[22m"
      puts "Run \e[1;94mrails stimulus_reflex:install:restart\e[0m to restart the installation process"
      puts
    else
      puts "✨ Installing \e[38;5;220mStimulusReflex\e[0m and \e[38;5;220mCableReady\e[0m ✨"
      puts
      puts "If you have any setup issues, please consult \e[4;97mhttps://docs.stimulusreflex.com/hello-world/setup\e[0m"
      puts "or get help on Discord: \e[4;97mhttps://discord.gg/stimulus-reflex\e[0m. \e[38;5;196mWe are here for you.\e[0m 💙"

      if Rails.root.join(".git").exist?
        puts
        puts "We recommend running \e[1;94mgit commit\e[0m before proceeding. A diff will be generated at the end."
      end

      entrypoint = if options.key? "entrypoint"
        options["entrypoint"]
      else
        StimulusReflex::Installer.auto_detect_entrypoint
      end

      StimulusReflex::Installer.installer_entrypoint_path.write(entrypoint)
    end

    # verify their bundler before starting, unless they explicitly specified on CLI
    if !used_bundler
      used_bundler = StimulusReflex::Installer.bundler
    end

    StimulusReflex::Installer.installer_bundler_path.write(used_bundler)

    FileUtils.touch("tmp/stimulus_reflex_installer/backups")
    File.write("tmp/stimulus_reflex_installer/template_src", File.expand_path("../../generators/stimulus_reflex/templates/", __dir__))

    `bin/spring stop` if defined?(Spring)

    # do the things
    SR_BUNDLERS[used_bundler].each do |template|
      run_install_template(template, trace: !!options["trace"])
    end

    puts
    puts "🎉 \e[1;92mStimulusReflex and CableReady have been successfully installed!\e[22m 🎉"
    puts
    puts "👉 \e[4;97mhttps://docs.stimulusreflex.com/hello-world/quickstart\e[0m"
    puts
    puts "Join over 2000 StimulusReflex developers on Discord: \e[4;97mhttps://discord.gg/stimulus-reflex\e[0m"
    puts

    backups = File.readlines("tmp/stimulus_reflex_installer/backups").map(&:chomp)

    if backups.any?
      puts "🙆 The following files were modified during installation:"
      puts
      backups.each { |backup| puts "  #{backup}" }
      puts
      puts "Each of these files has been backed up with a .bak extension. Please review the changes carefully."
      puts "If you're happy with the changes, you can delete the .bak files."
      puts
    end

    if Rails.root.join(".git").exist?
      system "git diff > tmp/stimulus_reflex_installer.diff"
      puts "🏮 A diff of all changes has been saved to \e[1mtmp/stimulus_reflex_installer.diff\e[22m"
      puts
    end

    if Rails.root.join("app/reflexes/example_reflex.rb").exist?
      launch = Rails.root.join("bin/dev").exist? ? "bin/dev" : "rails s"
      puts "🚀 Launch \e[1;94m#{launch}\e[0m to access the example at ⚡ \e[4;97mhttp://localhost:3000/example\e[0m ⚡"
      puts "Once you're finished with the example, you can remove it with \e[1;94mrails destroy stimulus_reflex example\e[0m"
      puts
    end

    FileUtils.touch(install_complete)
    `pkill -f spring` if Rails.root.join("tmp/stimulus_reflex_installer/kill_spring").exist?
    exit
  end

  namespace :install do
    desc "Restart StimulusReflex and CableReady installation"
    task :restart do
      FileUtils.rm_rf Rails.root.join("tmp/stimulus_reflex_installer")
      system "rails stimulus_reflex:install #{ARGV.join(" ")}"
      exit
    end

    desc <<~DESC
      Run specific StimulusReflex install steps

      #{SR_STEPS.sort.map { |step, description| "#{step.ljust(20)} #{description}" }.join("\n")}
    DESC
    task :step do
      def warning(step = nil, force_exit = true)
        return if step.to_s.include?("=")
        if step
          puts "⚠️  #{step} is not a valid step. Valid steps are: #{SR_STEPS.keys.join(", ")}"
        else
          puts "❌ You must specify a step to re-run. Valid steps are: #{SR_STEPS.keys.join(", ")}"
          puts "Example: \e[1;94mrails stimulus_reflex:install:step initializers\e[0m"
        end
        exit if force_exit
      end

      warning if ARGV.empty?

      ARGV.each do |step|
        SR_STEPS.include?(step) ? run_install_template(step, force: true) : warning(step, false)
      end

      run_install_template(:bundle, force: true)
      run_install_template(:yarn, force: true)

      exit
    end
  end
end
