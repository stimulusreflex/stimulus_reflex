include Rails.application.routes.url_helpers

STEPS = {
  "action_cable" => "Action Cable",
  "redis" => "Redis",
  "webpacker" => "Webpacker",
  "npm_packages" => "StimulusReflex and CableReady npm packages",
  "reflexes" => "Reflexes",
  "importmap" => "Import Maps",
  "esbuild" => "esbuild",
  "config" => "Client initialization",
  "initializers" => "StimulusReflex and CableReady initializers",
  "example" => "Create an Example Reflex",
  "development" => "development environment configuration",
  "spring" => "Launch spring, ruiner of days, into the sun",
  "mrujs" => "Swap out UJS for mrujs",
  "broadcaster" => "Make CableReady available to channels, controllers, jobs and models",
  "yarn" => "Resolve npm dependency changes"
}

FOOTGUNS = {
  "webpacker" => ["npm_packages", "webpacker", "config", "action_cable", "reflexes", "development", "initializers", "broadcaster", "example", "spring", "mrujs", "yarn"],
  "esbuild" => [],
  "vite" => [],
  "shakapacker" => [],
  "importmap" => []
}

def run_install_template(template, force: false)
  if Rails.root.join("tmp/stimulus_reflex_installer/halt").exist?
    FileUtils.rm(Rails.root.join("tmp/stimulus_reflex_installer/halt"))
    puts "StimulusReflex installation halted. Please fix the issues above and try again."
    exit
  end
  if Rails.root.join("tmp/stimulus_reflex_installer/#{template}").exist? && !force
    puts "👍 #{STEPS[template]}"
    return
  end
  system "#{RbConfig.ruby} ./bin/rails app:template LOCATION=#{File.expand_path("../../install/#{template}.rb", __dir__)} SKIP_SANITY_CHECK=true"
  puts "👍 #{STEPS[template]}" unless Rails.root.join("tmp/stimulus_reflex_installer/halt").exist?
end

# store a hash of the contents of Gemfile, so we know if we need to run bundle later
def gemfile_hash
  Digest::MD5.hexdigest(File.read(Rails.root.join("Gemfile")))
end

namespace :stimulus_reflex do
  desc "✨ Install StimulusReflex and CableReady ✨"
  task :install do
    install_complete = Rails.root.join("tmp/stimulus_reflex_installer/complete")

    if install_complete.exist?
      puts
      puts "✨ StimulusReflex and CableReady are already installed ✨"
      puts
      puts "To restart the installation process, run: rails stimulus_reflex:install:restart"
      puts
      puts "To get started, check out https://docs.stimulusreflex.com/hello-world/quickstart"
      puts "or get help on Discord: https://discord.gg/stimulus-reflex <- we're here for you!"
      puts
      exit
    end

    # if there is an installation in progress, continue where we left off
    cached_entrypoint = Rails.root.join("tmp/stimulus_reflex_installer/entrypoint")
    if cached_entrypoint.exist?
      entrypoint = File.read(cached_entrypoint)
      puts
      puts "✨ Resuming StimulusReflex and CableReady installation ✨"
      puts
      puts "If you have any setup issues, please consult https://docs.stimulusreflex.com/hello-world/setup"
      puts "or get help on Discord: https://discord.gg/stimulus-reflex <- we're here for you!"
      puts
      puts "Resuming installation into #{entrypoint}"
      puts "Run `rails stimulus_reflex:install:restart` to restart the installation process"
      puts
    else
      entrypoint = [
        "app/javascript",
        "app/frontend"
      ].find { |path| File.exist?(Rails.root.join(path)) } || "app/javascript"
      puts
      puts "✨ Installing StimulusReflex and CableReady ✨"
      puts
      puts "If you have any setup issues, please consult https://docs.stimulusreflex.com/hello-world/setup"
      puts "or get help on Discord: https://discord.gg/stimulus-reflex <- we're here for you!"
      puts
      puts "Where do JavaScript files live in your app? Our best guess is: #{entrypoint} 🤔"
      puts "Press enter to accept this, or type a different path."
      print "> "
      input = $stdin.gets.chomp
      entrypoint = input unless input.blank?
      FileUtils.mkdir_p(Rails.root.join("tmp/stimulus_reflex_installer"))
      File.write(cached_entrypoint, entrypoint)
    end

    # capture Gemfile signature to ensure that we don't run slow bundle unless required
    File.write("tmp/stimulus_reflex_installer/gemfile", gemfile_hash)

    # make sure we have a valid build tool specified, or proceed to automatic detection
    footgun = ["webpacker", "esbuild", "vite", "shakapacker", "importmap"].include?(ARGV[0]) ? ARGV[0] : nil

    # auto-detect build tool based on existing packages and configuration
    if Rails.root.join("config/importmap.rb").exist?
      footgun = "importmap"
    elsif Rails.root.join("package.json").exist?
      package_json = File.read(Rails.root.join("package.json"))
      footgun = "webpacker" if package_json.include?('"@rails/webpacker":')
      footgun = "esbuild" if package_json.include?('"esbuild":')
      footgun = "vite" if package_json.include?('"vite":')
      footgun = "shakapacker" if package_json.include?('"shakapacker":')
      if !footgun
        puts "❌ You must be using a node-based bundler such as esbuild, webpacker, vite or shakapacker (package.json) or importmap (config/importmap.rb) to use StimulusReflex."
        exit
      end
    else
      puts "❌ You must be using a node-based bundler such as esbuild, webpacker, vite or shakapacker (package.json) or importmap (config/importmap.rb) to use StimulusReflex."
      exit
    end

    # verify their bundler before starting, unless they explicitly specified on CLI
    if footgun != ARGV[0]
      puts
      puts "It looks like you're using #{footgun} as your bundler. Is that correct? (Y/n)"
      print "> "
      input = $stdin.gets.chomp
      if input.downcase == "n"
        puts
        puts "StimulusReflex installation supports: esbuild, webpacker, vite, shakapacker and importmap."
        puts "Please run `rails stimulus_reflex:install [bundler]` to install StimulusReflex and CableReady."
        exit
      end
    end

    # do the things
    FOOTGUNS[footgun].each do |template|
      run_install_template(template)
    end

    # compare current Gemfile signature to cached signature to determine if we need to run bundle
    system("bundle") if File.read("tmp/stimulus_reflex_installer/gemfile") != gemfile_hash

    puts
    puts "🎉 StimulusReflex and CableReady have been successfully installed! 🎉"
    puts
    puts "👉 https://docs.stimulusreflex.com/hello-world/quickstart"
    puts
    puts "Join over 2000 StimulusReflex developers on Discord: https://discord.gg/stimulus-reflex"
    puts

    if Rails.root.join("app/reflexes/example_reflex.rb").exist?
      puts "Launch `rails s` to access your example Reflex at ⚡ http://localhost:3000/example ⚡"
      puts "Once you're finished with the example, you can remove it with `rails destroy stimulus_reflex example`"
      puts
    end

    FileUtils.touch(install_complete)
  end

  namespace :install do
    desc "Install StimulusReflex and CableReady for webpacker 5.4"
    task :webpacker do
      system "rails stimulus_reflex:install webpacker"
    end

    desc "Install StimulusReflex and CableReady for esbuild"
    task :esbuild do
      system "rails stimulus_reflex:install esbuild"
    end

    desc "Install StimulusReflex and CableReady for vite"
    task :vite do
      system "rails stimulus_reflex:install vite"
    end

    desc "Install StimulusReflex and CableReady for shakapacker"
    task :shakapacker do
      system "rails stimulus_reflex:install shakapacker"
    end

    desc "Install StimulusReflex and CableReady for importmap-rails"
    task :importmap do
      system "rails stimulus_reflex:install importmap"
    end

    desc "Restart StimulusReflex and CableReady installation"
    task :restart do
      FileUtils.rm_rf Rails.root.join("tmp/stimulus_reflex_installer")
      system "rails stimulus_reflex:install"
    end

    desc "Re-run a specific StimulusReflex install step"
    task :step do
      def warning
        puts "❌ You must specify a step to re-run. Valid steps are: #{STEPS.keys.join(", ")}"
        puts "Example: rails stimulus_reflex:install:step initializers"
      end

      warning if ARGV.empty?

      ARGV.each do |step|
        STEPS.include?(step) ? run_install_template(step, force: true) : warning
      end
      exit
    end
  end
end
