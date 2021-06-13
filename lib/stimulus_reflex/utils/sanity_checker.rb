# frozen_string_literal: true

class StimulusReflex::SanityChecker
  LATEST_VERSION_FORMAT = /^(\d+\.\d+\.\d+)$/
  NODE_VERSION_FORMAT = /(\d+\.\d+\.\d+.*):/
  JSON_VERSION_FORMAT = /(\d+\.\d+\.\d+.*)"/

  class << self
    def check!
      return if StimulusReflex.config.on_failed_sanity_checks == :ignore
      return if called_by_installer?
      return if called_by_generate_config?
      return if called_by_rake?

      instance = new
      instance.check_caching_enabled
      instance.check_javascript_package_version
      instance.check_default_url_config
      instance.check_new_version_available
    end

    private

    def called_by_installer?
      Rake.application.top_level_tasks.include? "stimulus_reflex:install"
    rescue
      false
    end

    def called_by_generate_config?
      ARGV.include? "stimulus_reflex:initializer"
    end

    def called_by_rake?
      caller.find { |c| c.include?("/gems/rake-") }
    end
  end

  def check_caching_enabled
    unless caching_enabled?
      warn_and_exit <<~WARN
        StimulusReflex requires caching to be enabled. Caching allows the session to be modified during ActionCable requests.
        To enable caching in development, run:
          rails dev:cache

      WARN
    end

    unless not_null_store?
      warn_and_exit <<~WARN
        StimulusReflex requires caching to be enabled. Caching allows the session to be modified during ActionCable requests.
        But your config.cache_store is set to :null_store, so it won't work.

      WARN
    end
  end

  def check_default_url_config
    return if StimulusReflex.config.on_missing_default_urls == :ignore
    unless default_url_config_set?
      puts <<~WARN
        StimulusReflex strongly suggests that you set default_url_options in your environment files. Otherwise, ActionController #{ "and ActionMailer " if defined?(ActionMailer) }will default to example.com when rendering route helpers.

        You can set your URL options in config/environments/#{Rails.env}.rb

          config.action_controller.default_url_options = {host: "localhost", port: 3000}
          #{ "config.action_mailer.default_url_options = {host: \"localhost\", port: 3000}\n" if defined?(ActionMailer) }
        Please update every environment with the appropriate URL. Typically, no port is necessary in production.

      WARN
    end
  end

  def check_javascript_package_version
    if javascript_package_version.nil?
      warn_and_exit <<~WARN
        Can't locate the stimulus_reflex npm package.
        Either add it to your package.json as a dependency or use "yarn link stimulus_reflex" if you are doing development.

      WARN
    end

    unless javascript_version_matches?
      warn_and_exit <<~WARN
        The stimulus_reflex npm package version (#{javascript_package_version}) does not match the Rubygem version (#{gem_version}).
        To update the stimulus_reflex npm package:
          yarn upgrade stimulus_reflex@#{gem_version}

      WARN
    end
  end

  def check_new_version_available
    return unless Rails.env.development?
    return if StimulusReflex.config.on_new_version_available == :ignore
    return unless using_stable_release
    begin
      latest_version = URI.open("https://raw.githubusercontent.com/stimulusreflex/stimulus_reflex/master/LATEST", open_timeout: 1, read_timeout: 1).read.strip
      if latest_version != StimulusReflex::VERSION
        puts <<~WARN

          There is a new version of StimulusReflex available!
          Current: #{StimulusReflex::VERSION} Latest: #{latest_version}

          If you upgrade, it is very important that you update BOTH Gemfile and package.json
          Then, run `bundle install && yarn install` to update to #{latest_version}.

        WARN
        exit if StimulusReflex.config.on_new_version_available == :exit
      end
    rescue
      puts "StimulusReflex #{StimulusReflex::VERSION} update check skipped: connection timeout"
    end
  end

  def caching_enabled?
    Rails.application.config.action_controller.perform_caching
  end

  def not_null_store?
    Rails.application.config.cache_store != :null_store
  end

  def default_url_config_set?
    if defined?(ActionMailer)
      Rails.application.config.action_controller.default_url_options && Rails.application.config.action_mailer.default_url_options
    else
      Rails.application.config.action_controller.default_url_options
    end
  end

  def javascript_version_matches?
    javascript_package_version == gem_version
  end

  def using_stable_release
    stable = StimulusReflex::VERSION.match?(LATEST_VERSION_FORMAT)
    puts "StimulusReflex #{StimulusReflex::VERSION} update check skipped: pre-release build" unless stable
    stable
  end

  def gem_version
    @_gem_version ||= StimulusReflex::VERSION.gsub(".pre", "-pre")
  end

  def javascript_package_version
    @_js_version ||= find_javascript_package_version
  end

  def find_javascript_package_version
    if (match = search_file(package_json_path, regex: /version/))
      match[JSON_VERSION_FORMAT, 1]
    elsif (match = search_file(yarn_lock_path, regex: /^stimulus_reflex/))
      match[NODE_VERSION_FORMAT, 1]
    end
  end

  def search_file(path, regex:)
    return unless File.exist?(path)
    File.foreach(path).grep(regex).first
  end

  def package_json_path
    Rails.root.join("node_modules", "stimulus_reflex", "package.json")
  end

  def yarn_lock_path
    Rails.root.join("yarn.lock")
  end

  def warn_and_exit(text)
    puts 
    puts "Heads up! 🔥"
    puts
    puts text
    puts
    if StimulusReflex.config.on_failed_sanity_checks == :exit
      puts <<~INFO
        If you know what you are doing and you want to start the application anyway, you can add the following directive to the StimulusReflex initializer:

          StimulusReflex.configure do |config|
            config.on_failed_sanity_checks = :warn
          end

        You can create a StimulusReflex initializer with the command:

          bundle exec rails generate stimulus_reflex:initializer

      INFO
      exit false
    end
  end
end
