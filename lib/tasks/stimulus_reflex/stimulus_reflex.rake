include Rails.application.routes.url_helpers

STEPS = {
  "action_cable" => "Action Cable",
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
  "esbuild" => ["npm_packages", "esbuild", "config", "action_cable", "reflexes", "development", "initializers", "broadcaster", "example", "spring", "mrujs", "yarn"],
  "vite" => [],
  "shakapacker" => [],
  "importmap" => ["config", "action_cable", "importmap", "reflexes", "development", "initializers", "broadcaster", "example", "spring", "mrujs"]
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

    puts <<~ASCII

                                             \e[38;5;188m:\e[38;5;181m~\e[38;5;188m:\e[38;5;225m+
                                          \e[38;5;181m~\e[38;5;145m.\e[38;5;181m~\e[38;5;182m:\e[38;5;145m~\e[38;5;175m~\e[38;5;139m.\e[38;5;181m:\e[38;5;225m+
                                            \e[38;5;231m+\e[38;5;181m:\e[38;5;139m..\e[38;5;138m.\e[38;5;145m~\e[38;5;138m.\e[38;5;175m~\e[38;5;188m:
             \e[38;5;231m+\e[38;5;182m:\e[38;5;188m+\e[38;5;188m+\e[38;5;181m~\e[38;5;231m+\e[0m          \e[38;5;231m+\e[38;5;224m+\e[38;5;188m:\e[38;5;182m:\e[38;5;182m:\e[38;5;182m:\e[38;5;182m:\e[38;5;188m:\e[38;5;188m:\e[38;5;224m+\e[38;5;225m+\e[38;5;231m+\e[0m  \e[38;5;231m+\e[38;5;188m+\e[38;5;138m.\e[38;5;139m.\e[38;5;139m.\e[38;5;188m:\e[38;5;139m.\e[38;5;175m~\e[38;5;181m~
            \e[38;5;224m+\e[38;5;182m:\e[38;5;175m~\e[38;5;225m+\e[38;5;182m:\e[38;5;139m.\e[38;5;139m~\e[0m       \e[38;5;225m+\e[38;5;188m:\e[38;5;182m:\e[38;5;182m~\e[38;5;182m~\e[38;5;218m~\e[38;5;218m:\e[38;5;218m~\e[38;5;175m~\e[38;5;181m~\e[38;5;182m:\e[38;5;182m:\e[38;5;182m:\e[38;5;182m~\e[38;5;182m~\e[38;5;182m:\e[38;5;182m:\e[38;5;181m:\e[38;5;181m~\e[38;5;181m~\e[38;5;182m:\e[38;5;224m+\e[38;5;182m:\e[38;5;181m~\e[38;5;175m~\e[38;5;181m~
           \e[38;5;231m+\e[38;5;181m~\e[38;5;175m.\e[38;5;139m.\e[38;5;188m+\e[38;5;139m.\e[38;5;175m.\e[38;5;139m.\e[38;5;231m+\e[0m   \e[38;5;225m+\e[38;5;188m:\e[38;5;181m~\e[38;5;181m~\e[38;5;182m:\e[38;5;182m:\e[38;5;188m:\e[38;5;182m:\e[38;5;181m~\e[38;5;175m~\e[38;5;218m:\e[38;5;181m~\e[38;5;181m~\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;224m+\e[38;5;182m:\e[38;5;182m~\e[38;5;175m~\e[38;5;182m~\e[38;5;188m+
           \e[38;5;188m+\e[38;5;181m~\e[38;5;139m.\e[38;5;139m.\e[38;5;139m.\e[38;5;138m.\e[38;5;175m.\e[38;5;138m \e[38;5;182m:\e[38;5;188m:\e[38;5;182m:\e[38;5;181m~\e[38;5;181m~\e[38;5;181m~\e[38;5;182m:\e[38;5;182m:\e[38;5;224m:\e[38;5;224m+\e[38;5;182m:\e[38;5;218m:\e[38;5;224m+\e[38;5;182m:\e[38;5;175m~\e[38;5;175m~\e[38;5;218m:\e[38;5;224m:\e[38;5;224m+\e[38;5;224m:\e[38;5;224m+\e[38;5;224m+\e[38;5;224m:\e[38;5;224m:\e[38;5;224m+\e[38;5;224m:\e[38;5;218m:\e[38;5;224m:\e[38;5;224m+\e[38;5;175m~\e[38;5;218m~\e[38;5;181m~\e[38;5;231m+
            \e[38;5;181m:\e[38;5;182m~\e[38;5;139m.\e[38;5;175m~\e[38;5;181m~\e[38;5;175m.\e[38;5;175m~\e[38;5;175m~\e[38;5;139m~\e[38;5;181m~\e[38;5;182m:\e[38;5;218m:\e[38;5;224m:\e[38;5;225m+\e[38;5;224m:\e[38;5;182m:\e[38;5;175m~\e[38;5;139m.\e[38;5;139m.\e[38;5;182m:\e[38;5;224m:\e[38;5;181m~\e[38;5;218m:\e[38;5;225m+\e[38;5;182m~\e[38;5;182m:\e[38;5;182m:\e[38;5;218m:\e[38;5;218m:\e[38;5;224m:\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;218m:\e[38;5;175m.\e[38;5;218m:\e[38;5;182m:
             \e[38;5;182m:\e[38;5;182m~\e[38;5;181m~\e[38;5;182m~\e[38;5;224m:\e[38;5;225m+\e[38;5;225m:\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;218m:\e[38;5;175m.\e[38;5;139m.\e[38;5;139m.\e[38;5;139m.\e[38;5;139m~\e[38;5;175m.\e[38;5;175m.\e[38;5;139m.\e[38;5;182m:\e[38;5;182m:\e[38;5;139m.\e[38;5;175m.\e[38;5;175m.\e[38;5;175m.\e[38;5;175m.\e[38;5;175m.\e[38;5;181m~\e[38;5;182m:\e[38;5;224m+\e[38;5;225m+\e[38;5;225m+\e[38;5;224m:\e[38;5;175m.\e[38;5;218m:\e[38;5;181m~
              \e[38;5;188m+\e[38;5;182m~\e[38;5;182m:\e[38;5;181m~\e[38;5;182m:\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;225m:\e[38;5;225m+\e[38;5;218m:\e[38;5;138m.\e[38;5;139m.\e[38;5;138m.\e[38;5;139m.\e[38;5;175m.\e[38;5;175m.\e[38;5;175m.\e[38;5;175m~\e[38;5;181m~\e[38;5;225m+\e[38;5;225m+\e[38;5;182m:\e[38;5;182m:\e[38;5;182m~\e[38;5;181m~\e[38;5;175m~\e[38;5;139m~\e[38;5;139m.\e[38;5;139m.\e[38;5;139m.\e[38;5;182m~\e[38;5;225m+\e[38;5;225m+\e[38;5;139m.\e[38;5;182m~\e[38;5;181m~\e[38;5;188m+
                \e[38;5;188m:\e[38;5;182m~\e[38;5;182m~\e[38;5;182m:\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;182m~\e[38;5;139m~\e[38;5;139m.\e[38;5;139m.\e[38;5;175m.\e[38;5;181m~\e[38;5;182m:\e[38;5;182m:\e[38;5;182m~\e[38;5;182m:\e[38;5;182m~\e[38;5;181m~\e[38;5;182m~\e[38;5;182m:\e[38;5;182m~\e[38;5;182m~\e[38;5;182m~\e[38;5;181m:\e[38;5;181m~\e[38;5;139m.\e[38;5;139m.\e[38;5;96m \e[38;5;138m.\e[38;5;182m:\e[38;5;181m~\e[38;5;145m~\e[38;5;182m~\e[38;5;181m:\e[38;5;188m+\e[0m        \e[38;5;231m+\e[38;5;224m+\e[38;5;188m:
                 \e[38;5;188m:\e[38;5;182m~\e[38;5;181m~\e[38;5;182m~\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;175m~\e[38;5;139m \e[38;5;139m~\e[38;5;181m:\e[38;5;181m~\e[38;5;181m~\e[38;5;182m:\e[38;5;188m:\e[38;5;224m+\e[38;5;231m+\e[38;5;231mo\e[38;5;231m+\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231m+\e[38;5;225m+\e[38;5;188m:\e[38;5;181m~\e[38;5;139m~\e[38;5;96m \e[38;5;139m.\e[38;5;182m:\e[38;5;182m:\e[38;5;188m:\e[38;5;182m~\e[38;5;181m~\e[38;5;182m~\e[38;5;182m:\e[38;5;188m+\e[38;5;224m+\e[38;5;224m+\e[38;5;224m+\e[38;5;188m:\e[38;5;182m:\e[38;5;181m~\e[38;5;182m~\e[38;5;181m~
                  \e[38;5;181m~\e[38;5;182m~\e[38;5;139m.\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;224m:\e[38;5;138m.\e[38;5;139m.\e[38;5;181m~\e[38;5;181m~\e[38;5;188m:\e[38;5;231m+\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231m+\e[38;5;182m~\e[38;5;175m~\e[38;5;181m~\e[38;5;181m~\e[38;5;218m:\e[38;5;182m:\e[38;5;224m+\e[38;5;224m:\e[38;5;182m:\e[38;5;182m:\e[38;5;182m:\e[38;5;182m~\e[38;5;182m~\e[38;5;181m~\e[38;5;139m~\e[38;5;139m.\e[38;5;175m~\e[38;5;182m:\e[38;5;231m+
                 \e[38;5;231m+\e[38;5;181m~\e[38;5;181m~\e[38;5;139m.\e[38;5;224m+\e[38;5;225m+\e[38;5;225m+\e[38;5;182m~\e[38;5;139m~\e[38;5;139m~\e[38;5;181m~\e[38;5;188m+\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;225m+\e[38;5;182m:\e[38;5;188m:\e[38;5;188m+\e[38;5;231m+\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;181m~\e[38;5;175m~\e[38;5;181m~\e[38;5;225m+\e[38;5;225m+\e[38;5;224m:\e[38;5;224m:\e[38;5;224m+\e[38;5;182m:\e[38;5;182m~\e[38;5;182m:\e[38;5;182m:\e[38;5;181m~\e[38;5;181m~\e[38;5;182m:\e[38;5;188m+
                 \e[38;5;182m:\e[38;5;175m~\e[38;5;182m:\e[38;5;181m~\e[38;5;225m:\e[38;5;225m+\e[38;5;225m+\e[38;5;182m:\e[38;5;181m~\e[38;5;175m~\e[38;5;139m.\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;188m:\e[38;5;139m.\e[38;5;175m.\e[38;5;139m.\e[38;5;139m.\e[38;5;139m~\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;139m~\e[38;5;182m~\e[38;5;181m~\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;218m:\e[38;5;182m~\e[38;5;182m~\e[38;5;182m~\e[38;5;182m:\e[38;5;182m:\e[38;5;224m+\e[38;5;231m+
               \e[38;5;188m:\e[38;5;181m~\e[38;5;181m~\e[38;5;224m+\e[38;5;188m:\e[38;5;182m:\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;181m~\e[38;5;139m.\e[38;5;145m~\e[38;5;188m:\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231m+\e[38;5;181m~\e[38;5;175m.\e[38;5;175m~\e[38;5;175m.\e[38;5;182m:\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231mo\e[38;5;231m+\e[38;5;188m:\e[38;5;139m.\e[38;5;182m:\e[38;5;181m~\e[38;5;225m+\e[38;5;225m+\e[38;5;182m:\e[38;5;175m~\e[38;5;218m~\e[38;5;182m~\e[38;5;188m:\e[38;5;231m+
       \e[38;5;182m:\e[38;5;182m:\e[38;5;182m:\e[38;5;182m:\e[38;5;182m~\e[38;5;181m~\e[38;5;145m~\e[38;5;139m~\e[38;5;181m~\e[38;5;182m:\e[38;5;224m+\e[38;5;182m:\e[38;5;182m:\e[38;5;225m+\e[38;5;225m+\e[38;5;225m:\e[38;5;225m+\e[38;5;225m+\e[38;5;224m+\e[38;5;175m~\e[38;5;181m~\e[38;5;188m:\e[38;5;188m+\e[38;5;194m+\e[38;5;231m+\e[38;5;231mo\e[38;5;231m+\e[38;5;231mo\e[38;5;231m+\e[38;5;188m+\e[38;5;188m+\e[38;5;188m+\e[38;5;231mo\e[38;5;231m+\e[38;5;231mo\e[38;5;188m+\e[38;5;188m+\e[38;5;188m:\e[38;5;181m~\e[38;5;182m~\e[38;5;175m~\e[38;5;218m:\e[38;5;225m:\e[38;5;224m+\e[38;5;139m.\e[38;5;218m:\e[38;5;182m~\e[38;5;188m:
       \e[38;5;188m:\e[38;5;181m~\e[38;5;175m.\e[38;5;175m.\e[38;5;139m.\e[38;5;139m.\e[38;5;139m.\e[38;5;139m.\e[38;5;182m~\e[38;5;182m:\e[38;5;181m~\e[38;5;181m~\e[38;5;182m:\e[38;5;182m~\e[38;5;182m:\e[38;5;218m:\e[38;5;225m+\e[38;5;225m+\e[38;5;225m+\e[38;5;218m:\e[38;5;175m~\e[38;5;181m~\e[38;5;182m:\e[38;5;188m+\e[38;5;231m+\e[38;5;231m+\e[38;5;231m+\e[38;5;231m+\e[38;5;231m+\e[38;5;231m+\e[38;5;188m+\e[38;5;188m+\e[38;5;188m+\e[38;5;188m:\e[38;5;188m:\e[38;5;182m:\e[38;5;182m~\e[38;5;181m~\e[38;5;181m~\e[38;5;175m~\e[38;5;182m:\e[38;5;182m~\e[38;5;139m~\e[38;5;182m~\e[38;5;138m.\e[38;5;218m:\e[38;5;181m~\e[38;5;188m+
          \e[38;5;188m+\e[38;5;175m~\e[38;5;218m:\e[38;5;175m~\e[38;5;182m~\e[38;5;175m~\e[38;5;175m.\e[38;5;175m~\e[38;5;175m.\e[38;5;175m~\e[38;5;181m~\e[38;5;182m~\e[38;5;182m~\e[38;5;182m~\e[38;5;182m:\e[38;5;225m:\e[38;5;225m+\e[38;5;224m+\e[38;5;182m:\e[38;5;181m~\e[38;5;181m:\e[38;5;181m~\e[38;5;181m~\e[38;5;181m~\e[38;5;181m~\e[38;5;182m:\e[38;5;182m:\e[38;5;182m:\e[38;5;182m~\e[38;5;182m~\e[38;5;182m~\e[38;5;182m~\e[38;5;182m~\e[38;5;175m~\e[38;5;96m \e[38;5;96m \e[38;5;138m.\e[38;5;139m.\e[38;5;139m~\e[38;5;139m.\e[38;5;139m~\e[38;5;139m.\e[38;5;181m~\e[38;5;182m:\e[38;5;182m:
          \e[38;5;181m~\e[38;5;218m~\e[38;5;182m~\e[38;5;182m:\e[38;5;145m~\e[38;5;138m.\e[38;5;175m.\e[38;5;139m~\e[38;5;181m~\e[38;5;188m:\e[38;5;224m+\e[38;5;188m+\e[38;5;182m:\e[38;5;182m:\e[38;5;182m~\e[38;5;181m~\e[38;5;225m:\e[38;5;218m:\e[38;5;182m:\e[38;5;182m:\e[38;5;175m~\e[38;5;138m \e[38;5;132m \e[38;5;96m \e[38;5;139m.\e[38;5;175m~\e[38;5;181m~\e[38;5;181m~\e[38;5;181m:\e[38;5;181m~\e[38;5;181m~\e[38;5;181m~\e[38;5;145m~\e[38;5;139m.\e[38;5;138m \e[38;5;139m~\e[38;5;181m~\e[38;5;182m~\e[38;5;225m+\e[38;5;225m+\e[38;5;224m:\e[38;5;181m~\e[38;5;181m~\e[38;5;182m:\e[38;5;182m~\e[38;5;188m:
         \e[38;5;231m+\e[38;5;181m~\e[38;5;182m~\e[38;5;188m:\e[0m \e[38;5;145m~\e[38;5;139m.\e[38;5;181m~\e[38;5;231m+\e[0m     \e[38;5;182m:\e[38;5;182m~\e[38;5;181m~\e[38;5;181m~\e[38;5;175m~\e[38;5;181m~\e[38;5;175m~\e[38;5;139m~\e[38;5;139m.\e[38;5;181m~\e[38;5;139m.\e[38;5;138m.\e[38;5;139m.\e[38;5;139m.\e[38;5;175m~\e[38;5;175m~\e[38;5;175m.\e[38;5;139m~\e[38;5;139m.\e[38;5;139m.\e[38;5;175m~\e[38;5;218m:\e[38;5;225m+\e[38;5;225m+\e[38;5;225m:\e[38;5;218m:\e[38;5;182m~\e[38;5;175m~\e[38;5;182m~\e[38;5;182m:\e[38;5;188m:\e[38;5;182m:\e[38;5;175m~\e[38;5;182m:
          \e[38;5;188m:\e[38;5;188m+\e[0m  \e[38;5;188m:\e[38;5;188m:\e[0m        \e[38;5;181m~\e[38;5;182m:\e[38;5;175m~\e[38;5;224m+\e[38;5;218m:\e[38;5;218m:\e[38;5;224m:\e[38;5;224m:\e[38;5;225m+\e[38;5;225m+\e[38;5;218m:\e[38;5;182m:\e[38;5;182m~\e[38;5;181m~\e[38;5;181m~\e[38;5;181m~\e[38;5;182m~\e[38;5;182m:\e[38;5;218m:\e[38;5;224m+\e[38;5;224m:\e[38;5;218m:\e[38;5;182m:\e[38;5;182m~\e[38;5;182m~\e[38;5;175m~\e[38;5;181m~\e[38;5;224m+\e[38;5;224m:\e[38;5;182m:\e[38;5;225m+\e[38;5;182m:\e[38;5;175m~\e[38;5;182m~
                        \e[38;5;188m:\e[38;5;182m~\e[38;5;175m.\e[38;5;225m:\e[38;5;218m:\e[38;5;181m~\e[38;5;181m~\e[38;5;182m:\e[38;5;182m:\e[38;5;218m:\e[38;5;218m:\e[38;5;218m:\e[38;5;218m:\e[38;5;218m:\e[38;5;218m:\e[38;5;182m:\e[38;5;182m:\e[38;5;182m~\e[38;5;182m~\e[38;5;182m~\e[38;5;182m~\e[38;5;182m:\e[38;5;218m:\e[38;5;218m:\e[38;5;182m~\e[38;5;175m~\e[38;5;182m~\e[38;5;182m:\e[38;5;182m:\e[38;5;181m~\e[38;5;188m:\e[38;5;225m+\e[38;5;182m:\e[38;5;175m~\e[38;5;181m:\e[38;5;231m+
                        \e[38;5;188m:\e[38;5;182m~\e[38;5;175m~\e[38;5;225m+\e[38;5;225m+\e[38;5;182m:\e[38;5;181m~\e[38;5;182m~\e[38;5;182m~\e[38;5;175m~\e[38;5;182m~\e[38;5;182m:\e[38;5;182m~\e[38;5;182m:\e[38;5;218m~\e[38;5;218m:\e[38;5;218m:\e[38;5;218m:\e[38;5;218m:\e[38;5;218m:\e[38;5;218m:\e[38;5;218m:\e[38;5;218m:\e[38;5;218m~\e[38;5;218m:\e[38;5;218m:\e[38;5;218m:\e[38;5;218m~\e[38;5;218m~\e[38;5;182m~\e[38;5;182m:\e[38;5;182m:\e[38;5;182m~\e[38;5;139m~\e[38;5;182m~\e[38;5;181m:\e[38;5;231m+
                        \e[38;5;182m:\e[38;5;182m~\e[38;5;181m~\e[38;5;225m+\e[38;5;182m:\e[38;5;188m:\e[38;5;225m+\e[38;5;224m+\e[38;5;182m:\e[38;5;181m~\e[38;5;182m~\e[38;5;218m:\e[38;5;218m:\e[38;5;218m:\e[38;5;218m:\e[38;5;182m:\e[38;5;182m~\e[38;5;182m:\e[38;5;182m:\e[38;5;182m:\e[38;5;182m:\e[38;5;188m:\e[38;5;188m:\e[38;5;188m+\e[38;5;188m:\e[38;5;188m+\e[38;5;188m:\e[38;5;188m+\e[38;5;188m:\e[38;5;182m:\e[38;5;182m:\e[38;5;182m~\e[38;5;182m~\e[38;5;182m:\e[38;5;218m:\e[38;5;182m:\e[38;5;182m:
                        \e[38;5;181m~\e[38;5;182m~\e[38;5;181m~\e[38;5;182m:\e[38;5;182m:\e[38;5;182m:\e[38;5;182m:\e[38;5;182m~\e[38;5;218m~\e[38;5;218m:\e[38;5;182m:\e[38;5;182m~\e[38;5;182m:\e[38;5;188m:\e[38;5;224m+\e[38;5;231m+\e[0m \e[38;5;231m+\e[0m              \e[38;5;231m+\e[38;5;224m+\e[38;5;188m:\e[38;5;188m:\e[38;5;224m+
                        \e[38;5;181m~\e[38;5;182m~\e[38;5;138m.\e[38;5;181m~\e[38;5;182m:\e[38;5;218m~\e[38;5;218m~\e[38;5;182m:\e[38;5;182m:\e[38;5;188m+\e[38;5;231m+
                       \e[38;5;231m+\e[38;5;181m~\e[38;5;182m:\e[38;5;139m.\e[38;5;182m:\e[38;5;218m~\e[38;5;182m~\e[38;5;188m:\e[38;5;231m+
                        \e[38;5;182m:\e[38;5;182m~\e[38;5;218m:\e[38;5;182m~\e[38;5;188m:
                        \e[38;5;231m+\e[38;5;182m:\e[38;5;182m~\e[38;5;188m+
      \e[0m
    ASCII

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
    cached_entrypoint = Rails.root.join("tmp/stimulus_reflex_installer/entrypoint")
    if cached_entrypoint.exist?
      entrypoint = File.read(cached_entrypoint)
      puts "✨ Resuming \e[38;5;220mStimulusReflex\e[0m and \e[38;5;220mCableReady\e[0m installation ✨"
      puts
      puts "If you have any setup issues, please consult \e[4;97mhttps://docs.stimulusreflex.com/hello-world/setup\e[0m"
      puts "or get help on Discord: \e[4;97mhttps://discord.gg/stimulus-reflex\e[0m. \e[38;5;196mWe are here for you.\e[0m 💙"
      puts
      puts "Resuming installation into \e[1m#{entrypoint}\e[22m"
      puts "Run \e[1;94mrails stimulus_reflex:install:restart\e[0m to restart the installation process"
      puts
    else
      entrypoint = [
        "app/javascript",
        "app/frontend"
      ].find { |path| File.exist?(Rails.root.join(path)) } || "app/javascript"
      puts "✨ Installing \e[38;5;220mStimulusReflex\e[0m and \e[38;5;220mCableReady\e[0m ✨"
      puts
      puts "If you have any setup issues, please consult \e[4;97mhttps://docs.stimulusreflex.com/hello-world/setup\e[0m"
      puts "or get help on Discord: \e[4;97mhttps://discord.gg/stimulus-reflex\e[0m. \e[38;5;196mWe are here for you.\e[0m 💙"
      if Rails.root.join(".git").exist?
        puts
        puts "We recommend running \e[1;94mgit commit\e[0m before proceeding. A diff will be generated at the end."
      end
      puts
      puts "Where do JavaScript files live in your app? Our best guess is: \e[1m#{entrypoint}\e[22m 🤔"
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
      puts "It looks like you're using \e[1m#{footgun}\e[22m as your bundler. Is that correct? (Y/n)"
      print "> "
      input = $stdin.gets.chomp
      if input.downcase == "n"
        puts
        puts "StimulusReflex installation supports: esbuild, webpacker, vite, shakapacker and importmap."
        puts "Please run \e[1;94mrails stimulus_reflex:install [bundler]\e[0m to install StimulusReflex and CableReady."
        exit
      end
    end

    File.write("tmp/stimulus_reflex_installer/footgun", footgun)
    FileUtils.touch("tmp/stimulus_reflex_installer/backups")

    # do the things
    FOOTGUNS[footgun].each do |template|
      run_install_template(template)
    end

    # compare current Gemfile signature to cached signature to determine if we need to run bundle
    system("bundle") if File.read("tmp/stimulus_reflex_installer/gemfile") != gemfile_hash

    puts
    puts "🎉 \e[1;92mStimulusReflex and CableReady have been successfully installed!\e[22m 🎉"
    puts
    puts "👉 \e[4;97mhttps://docs.stimulusreflex.com/hello-world/quickstart\e[0m"
    puts
    puts "Join over 2000 StimulusReflex developers on Discord: \e[4;97mhttps://discord.gg/stimulus-reflex\e[0m"
    puts

    backups = File.readlines("tmp/stimulus_reflex_installer/backups").map(&:chomp)
    if backups.any?
      puts "⚠️  The following files were regenerated during installation:"
      puts
      backups.each { |backup| puts "  #{backup}" }
      puts
      puts "Each of these files has been backed up with a .bak extension. Please review the changes carefully."
      puts "If you're happy with the changes, you can delete the .bak files."
      puts
    end

    if Rails.root.join(".git").exist?
      system "git diff > tmp/stimulus_reflex_installer.diff"
      puts "A diff of all changes has been saved to \e[1mtmp/stimulus_reflex_installer.diff\e[22m."
      puts
    end

    if Rails.root.join("app/reflexes/example_reflex.rb").exist?
      launch = Rails.root.join("bin/dev").exist? ? "bin/dev" : "rails s"
      puts "Launch \e[1;94m#{launch}\e[0m to access your example Reflex at ⚡ \e[4;97mhttp://localhost:3000/example\e[0m ⚡"
      puts "Once you're finished with the example, you can remove it with \e[1;94mrails destroy stimulus_reflex example\e[0m"
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
        puts "Example: \e[1;94mrails stimulus_reflex:install:step initializers\e[0m"
      end

      warning if ARGV.empty?

      ARGV.each do |step|
        STEPS.include?(step) ? run_install_template(step, force: true) : warning
      end
      exit
    end
  end
end
