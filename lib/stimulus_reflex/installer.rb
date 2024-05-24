# frozen_string_literal: true

require "thor"

module StimulusReflex
  class Installer
    include Thor::Base
    include Thor::Actions

    source_root Dir.pwd

    ## Thor wrapper

    def self.create_file(...)
      new.create_file(...)
    end

    def self.append_file(...)
      new.append_file(...)
    end

    def self.copy_file(...)
      new.copy_file(...)
    end

    def self.say(...)
      new.say(...)
    end

    ### general utilities

    def self.fetch(step_path, file)
      relative_path = step_path + file
      location = template_src + relative_path

      Pathname.new(location)
    end

    def self.complete_step(step)
      create_file "tmp/stimulus_reflex_installer/#{step}", verbose: false
    end

    def self.create_or_append(path, *args, &block)
      FileUtils.touch(path)
      append_file(path, *args, &block)
    end

    def self.current_template
      ENV["LOCATION"].split("/").last.gsub(".rb", "")
    end

    def self.pack_path_missing?
      return false unless pack_path.nil?
      halt "#{friendly_pack_path} is missing. You need a valid application pack file to proceed."
    end

    def self.halt(message)
      say "❌ #{message}", :red
      create_file "tmp/stimulus_reflex_installer/halt", verbose: false
    end

    def self.backup(path, delete: false)
      if !path.exist?
        yield
        return
      end

      backup_path = Pathname.new("#{path}.bak")
      old_path = path.relative_path_from(Rails.root).to_s
      filename = path.to_path.split("/").last

      if backup_path.exist?
        if backup_path.read == path.read
          path.delete if delete
          yield
          return
        end
        backup_path.delete
      end

      copy_file(path, backup_path, verbose: false)
      path.delete if delete

      yield

      if path.read != backup_path.read
        create_or_append(backups_path, "#{old_path}\n", verbose: false)
      end
      say "📦 #{old_path} backed up as #{filename}.bak"
    end

    def self.add_gem(name)
      create_or_append(add_gem_list, "#{name}\n", verbose: false)
      say "☑️  Added #{name} to the Gemfile"
    end

    def self.remove_gem(name)
      create_or_append(remove_gem_list, "#{name}\n", verbose: false)
      say "❎ Removed #{name} from Gemfile"
    end

    def self.add_package(name)
      create_or_append(package_list, "#{name}\n", verbose: false)
      say "☑️  Enqueued #{name} to be added to dependencies"
    end

    def self.add_dev_package(name)
      create_or_append(dev_package_list, "#{name}\n", verbose: false)
      say "☑️  Enqueued #{name} to be added to dev dependencies"
    end

    def self.drop_package(name)
      create_or_append(drop_package_list, "#{name}\n", verbose: false)
      say "❎ Enqueued #{name} to be removed from dependencies"
    end

    def self.gemfile_hash
      Digest::MD5.hexdigest(gemfile_path.read)
    end

    ### memoized values

    def self.sr_npm_version
      @sr_npm_version ||= StimulusReflex::VERSION.gsub(".pre", "-pre").gsub(".rc", "-rc")
    end

    def self.cr_npm_version
      @cr_npm_version ||= CableReady::VERSION.gsub(".pre", "-pre").gsub(".rc", "-rc")
    end

    def self.package_json_path
      @package_json_path ||= Rails.root.join("package.json")
    end

    def self.installer_entrypoint_path
      create_dir_for_file_if_not_exists("tmp/stimulus_reflex_installer/entrypoint")
    end

    def self.entrypoint
      path = installer_entrypoint_path
      @entrypoint ||= File.exist?(path) ? File.read(path) : auto_detect_entrypoint
    end

    def self.auto_detect_entrypoint
      entrypoint = [
        "app/javascript",
        "app/frontend",
        "app/client",
        "app/webpack"
      ].find { |path| File.exist?(Rails.root.join(path)) } || "app/javascript"

      puts
      puts "Where do JavaScript files live in your app? Our best guess is: \e[1m#{entrypoint}\e[22m 🤔"
      puts "Press enter to accept this, or type a different path."
      print "> "

      input = Rails.env.test? ? "tmp/app/javascript" : $stdin.gets.chomp
      entrypoint = input unless input.blank?

      File.write(installer_entrypoint_path, entrypoint)

      entrypoint
    end

    def self.installer_bundler_path
      create_dir_for_file_if_not_exists("tmp/stimulus_reflex_installer/bundler")
    end

    def self.bundler
      path = installer_bundler_path
      @bundler ||= File.exist?(path) ? File.read(path) : auto_detect_bundler

      @bundler.inquiry
    end

    def self.auto_detect_bundler
      # auto-detect build tool based on existing packages and configuration
      if importmap_path.exist?
        bundler = "importmap"
      elsif package_json_path.exist?
        package_json = package_json_path.read

        bundler = "webpacker" if package_json.include?('"@rails/webpacker":')
        bundler = "esbuild" if package_json.include?('"esbuild":')
        bundler = "vite" if package_json.include?('"vite":')
        bundler = "shakapacker" if package_json.include?('"shakapacker":')

        if !bundler
          puts "❌ You must be using a node-based bundler such as esbuild, webpacker, vite or shakapacker (package.json) or importmap (config/importmap.rb) to use StimulusReflex."
          exit
        end
      else
        puts "❌ You must be using a node-based bundler such as esbuild, webpacker, vite or shakapacker (package.json) or importmap (config/importmap.rb) to use StimulusReflex."
        exit
      end

      puts
      puts "It looks like you're using \e[1m#{bundler}\e[22m as your bundler. Is that correct? (Y/n)"
      print "> "

      input = $stdin.gets.chomp

      if input.downcase == "n"
        puts
        puts "StimulusReflex installation supports: esbuild, webpacker, vite, shakapacker and importmap."
        puts "Please run \e[1;94mrails stimulus_reflex:install[bundler]\e[0m to install StimulusReflex and CableReady."
        exit
      end

      File.write(installer_bundler_path, bundler)

      bundler
    end

    def self.create_dir_if_not_exists(dir_path)
      FileUtils.mkdir_p(dir_path)

      Pathname.new(dir_path)
    end

    def self.create_dir_for_file_if_not_exists(file_path)
      dir_path = File.dirname(file_path)
      create_dir_if_not_exists(dir_path)

      Pathname.new(file_path)
    end

    def self.config_path
      @config_path ||= create_dir_if_not_exists(Rails.root.join(entrypoint, "config"))
    end

    def self.importmap_path
      @importmap_path ||= Rails.root.join("config/importmap.rb")
    end

    def self.friendly_importmap_path
      @friendly_importmap_path ||= importmap_path.relative_path_from(Rails.root).to_s
    end

    def self.pack
      @pack ||= pack_path.read
    end

    def self.friendly_pack_path
      @friendly_pack_path ||= pack_path.relative_path_from(Rails.root).to_s
    end

    def self.pack_path
      @pack_path ||= [
        Rails.root.join(entrypoint, "application.js"),
        Rails.root.join(entrypoint, "packs/application.js"),
        Rails.root.join(entrypoint, "entrypoints/application.js")
      ].find(&:exist?)
    end

    def self.package_list
      @package_list ||= Rails.root.join("tmp/stimulus_reflex_installer/npm_package_list")
    end

    def self.dev_package_list
      @dev_package_list ||= Rails.root.join("tmp/stimulus_reflex_installer/npm_dev_package_list")
    end

    def self.drop_package_list
      @drop_package_list ||= Rails.root.join("tmp/stimulus_reflex_installer/drop_npm_package_list")
    end

    def self.template_src
      @template_src ||= File.read("tmp/stimulus_reflex_installer/template_src")
    end

    def self.controllers_path
      @controllers_path ||= Rails.root.join(entrypoint, "controllers")
    end

    def self.gemfile_path
      @gemfile_path ||= Rails.root.join("Gemfile")
    end

    def self.gemfile
      @gemfile ||= gemfile_path.read
    end

    def self.prefix
      # standard:disable Style/RedundantStringEscape
      @prefix ||= {
        "vite" => "..\/",
        "webpacker" => "",
        "shakapacker" => "",
        "importmap" => "",
        "esbuild" => ".\/"
      }[bundler]
      # standard:enable Style/RedundantStringEscape
    end

    def self.application_record_path
      @application_record_path ||= Rails.root.join("app/models/application_record.rb")
    end

    def self.action_cable_initializer_path
      @action_cable_initializer_path ||= Rails.root.join("config/initializers/action_cable.rb")
    end

    def self.action_cable_initializer_working_path
      @action_cable_initializer_working_path ||= Rails.root.join(working, "action_cable.rb")
    end

    def self.development_path
      @development_path ||= Rails.root.join("config/environments/development.rb")
    end

    def self.development_working_path
      @development_working_path ||= Rails.root.join(working, "development.rb")
    end

    def self.backups_path
      @backups_path ||= Rails.root.join("tmp/stimulus_reflex_installer/backups")
    end

    def self.add_gem_list
      @add_gem_list ||= Rails.root.join("tmp/stimulus_reflex_installer/add_gem_list")
    end

    def self.remove_gem_list
      @remove_gem_list ||= Rails.root.join("tmp/stimulus_reflex_installer/remove_gem_list")
    end

    def self.options_path
      @options_path ||= Rails.root.join("tmp/stimulus_reflex_installer/options")
    end

    def self.options
      @options ||= YAML.safe_load(File.read(options_path))
    end

    def self.working
      @working ||= Rails.root.join("tmp/stimulus_reflex_installer/working")
    end

    ### support for development step

    def self.write_redis_recommendation(development_working, lines, index, gemfile)
      # provide a recommendation for using redis-session-store, including commented source code
      if !lines.index { |line| line.include?("StimulusReflex does not support :cookie_store") }
        lines.insert index + 1, <<~RUBY
          # StimulusReflex does not support :cookie_store, and we recommend switching to Redis.
          # To use `redis-session-store`, make sure to add it to your Gemfile and run `bundle install
          # config.session_store :redis_session_store,
          #   serializer: :json,
          #   on_redis_down: ->(*a) { Rails.logger.error("Redis down! \#{a.inspect}") },
          #   redis: {
          #     expire_after: 120.minutes,
          #     key_prefix: "session:",
          #     url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" }
          # }
        RUBY

        development_working.write lines.join
        # add redis-session-store to Gemfile, but comment it out
        if !gemfile.match?(/gem ['"]redis-session-store['"]/)
          append_file(gemfile_path, verbose: false) do
            <<~RUBY

              # StimulusReflex recommends using Redis for session storage
              # gem "redis-session-store", "0.11.5"
            RUBY
          end
          say "💡 Added redis-session-store 0.11.5 to the Gemfile, commented out"
        end
      end
    end

    def self.find_index(lines)
      # accomodate devs who modify their development.rb file structure
      if (index = lines.index { |line| line =~ /caching-dev/ })
        index += 3
      else
        index = lines.index { |line| line =~ /^Rails.application.configure do/ } + 1
      end
      index
    end
  end
end
