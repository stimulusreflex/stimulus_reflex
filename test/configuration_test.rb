# frozen_string_literal: true

require_relative "test_helper"

def revert_config_changes(key)
  previous_value = StimulusReflex.config.send(key)

  yield

  StimulusReflex.config.send("#{key}=", previous_value)
end

class MyLogger
end

class MyRackMiddleWare
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)

    [status, headers, response]
  end
end

class StimulusReflex::ConfigurationTest < ActionView::TestCase
  test "sets on_failed_sanity_checks" do
    revert_config_changes(:on_failed_sanity_checks) do
      assert_equal :exit, StimulusReflex.config.on_failed_sanity_checks

      StimulusReflex.configure do |config|
        config.on_failed_sanity_checks = :warn
      end

      assert_equal :warn, StimulusReflex.config.on_failed_sanity_checks
    end
  end

  test "shows on_new_version_available notice" do
    assert_output(nil, %(NOTICE: The `config.on_new_version_available` option has been removed from the StimulusReflex initializer. You can safely remove this option from your initializer.\n)) do
      StimulusReflex.configure do |config|
        config.on_new_version_available = :ignore
      end
    end

    assert_output(nil, %(NOTICE: The `config.on_new_version_available` option has been removed from the StimulusReflex initializer. You can safely remove this option from your initializer.\n)) do
      StimulusReflex.config.on_new_version_available
    end
  end

  test "sets on_missing_default_urls" do
    revert_config_changes(:on_missing_default_urls) do
      assert_equal :warn, StimulusReflex.config.on_missing_default_urls

      StimulusReflex.configure do |config|
        config.on_missing_default_urls = :ignore
      end

      assert_equal :ignore, StimulusReflex.config.on_missing_default_urls
    end
  end

  test "sets precompile_assets" do
    revert_config_changes(:precompile_assets) do
      assert StimulusReflex.config.precompile_assets

      StimulusReflex.configure do |config|
        config.precompile_assets = false
      end

      refute StimulusReflex.config.precompile_assets
    end
  end

  test "sets morph_operation" do
    revert_config_changes(:morph_operation) do
      assert_equal :morph, StimulusReflex.config.morph_operation

      StimulusReflex.configure do |config|
        config.morph_operation = :inner_html
      end

      assert_equal :inner_html, StimulusReflex.config.morph_operation
    end
  end

  test "sets replace_operation" do
    revert_config_changes(:replace_operation) do
      assert_equal :inner_html, StimulusReflex.config.replace_operation

      StimulusReflex.configure do |config|
        config.replace_operation = :morph
      end

      assert_equal :morph, StimulusReflex.config.replace_operation
    end
  end

  test "sets parent_channel" do
    revert_config_changes(:parent_channel) do
      assert_equal "ActionCable::Channel::Base", StimulusReflex.config.parent_channel

      StimulusReflex.configure do |config|
        config.parent_channel = "ApplicationCable::Channel"
      end

      assert_equal "ApplicationCable::Channel", StimulusReflex.config.parent_channel
    end
  end

  test "sets logger" do
    revert_config_changes(:logger) do
      assert_nil StimulusReflex.config.logger

      logger = MyLogger.new

      StimulusReflex.configure do |config|
        config.logger = logger
      end

      assert_equal logger, StimulusReflex.config.logger
    end
  end

  test "sets logging" do
    revert_config_changes(:logging) do
      logging = proc { "Custom Logger: #{session_id}" }

      refute_equal logging, StimulusReflex.config.logging

      StimulusReflex.configure do |config|
        config.logging = logging
      end

      assert_equal logging, StimulusReflex.config.logging
    end
  end

  test "uses middleware" do
    assert_empty StimulusReflex.config.middleware.middlewares

    StimulusReflex.configure do |config|
      config.middleware.use MyRackMiddleWare
    end

    assert_includes StimulusReflex.config.middleware.middlewares, MyRackMiddleWare
  end
end
