# frozen_string_literal: true

class StimulusReflex::SanityChecker
  class << self
    def check!
      return if ENV["SKIP_SANITY_CHECK"]
      return if StimulusReflex.config.on_failed_sanity_checks == :ignore
      return if called_by_installer?
      return if called_by_generate_config?
      return if called_by_rake?

      instance = new
      instance.check_caching_enabled
      # instance.check_default_url_config
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
      File.basename($PROGRAM_NAME) == "rake"
    end
  end

  def check_caching_enabled
    if caching_not_enabled?
      warn_and_exit <<~WARN
        👉 StimulusReflex requires caching to be enabled. Caching allows the session to be modified during ActionCable requests.

        To enable caching in development, run:

          rails dev:cache
      WARN
    end

    if using_null_store?
      warn_and_exit <<~WARN
        👉 StimulusReflex requires caching to be enabled.

        Caching allows the session to be modified during ActionCable requests. Your config.cache_store is set to :null_store, so it won't work.
      WARN
    end
  end

  def check_default_url_config
    return if StimulusReflex.config.on_missing_default_urls == :ignore
    if default_url_config_missing?
      puts <<~WARN
        👉 StimulusReflex strongly suggests that you set default_url_options in your environment files. Otherwise, ActionController #{"and ActionMailer " if defined?(ActionMailer)}will default to example.com when rendering route helpers.

        You can set your URL options in config/environments/#{Rails.env}.rb

          config.action_controller.default_url_options = {host: "localhost", port: 3000}
          #{"config.action_mailer.default_url_options = {host: \"localhost\", port: 3000}\n" if defined?(ActionMailer)}
        Please update every environment with the appropriate URL. Typically, no port is necessary in production.

      WARN
    end
  end

  def caching_not_enabled?
    Rails.application.config.action_controller.perform_caching == false
  end

  def using_null_store?
    Rails.application.config.cache_store == :null_store
  end

  def initializer_missing?
    File.exist?(Rails.root.join("config", "initializers", "stimulus_reflex.rb")) == false
  end

  def default_url_config_set?
    if defined?(ActionMailer)
      Rails.application.config.action_controller.default_url_options.blank? || Rails.application.config.action_mailer.default_url_options.blank?
    else
      Rails.application.config.action_controller.default_url_options.blank?
    end
  end

  def warn_and_exit(text)
    puts
    puts "Heads up! 🔥"
    puts
    puts text
    puts
    if StimulusReflex.config.on_failed_sanity_checks == :exit
      puts <<~INFO
        To ignore any warnings and start the application anyway, you can set the SKIP_SANITY_CHECK environment variable:

          SKIP_SANITY_CHECK=true rails

        To do this permanently, add the following directive to the StimulusReflex initializer:

          StimulusReflex.configure do |config|
            config.on_failed_sanity_checks = :warn
          end

      INFO
      exit false unless Rails.env.test?
    end
  end
end
