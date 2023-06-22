# frozen_string_literal: true

require "rails/generators/test_case"
require_relative "../test_helper"
require "./lib/generators/stimulus_reflex/stimulus_reflex_generator"
require "stimulus_reflex/installer"

def stub_entrypoint(path = "tmp/app/javascript")
  File.write(installer_entrypoint_path, path)
end

def stub_bundler(bundler = "importmaps")
  File.write(installer_bundler_path, bundler)
end

class StimulusReflexGeneratorTest < Rails::Generators::TestCase
  tests StimulusReflexGenerator
  destination File.expand_path("../../tmp", __FILE__)
  setup :prepare_destination

  setup do
    File.delete(installer_entrypoint_path) if File.exist?(installer_entrypoint_path)
    File.delete(installer_bundler_path) if File.exist?(installer_bundler_path)
    FileUtils.rm_rf("tmp/app")
    FileUtils.rm_rf("tmp/stimulus_reflex_installer")
  end

  teardown do
    File.delete(installer_entrypoint_path) if File.exist?(installer_entrypoint_path)
    File.delete(installer_bundler_path) if File.exist?(installer_bundler_path)
    FileUtils.rm_rf("tmp/app")
    FileUtils.rm_rf("tmp/stimulus_reflex_installer")
  end

  test "creates singular named controller and reflex files" do
    stub_entrypoint
    stub_bundler

    run_generator %w[demo]

    assert_file "../../tmp/app/javascript/controllers/demo_controller.js"
    assert_file "../../tmp/app/reflexes/demo_reflex.rb", /DemoReflex/
  end

  test "creates plural named controller and reflex files" do
    stub_entrypoint
    stub_bundler

    run_generator %w[posts]

    assert_file "../../tmp/app/javascript/controllers/posts_controller.js"
    assert_file "../../tmp/app/reflexes/posts_reflex.rb", /PostsReflex/
  end

  test "skips stimulus controller and reflex if option provided" do
    stub_entrypoint
    stub_bundler

    run_generator %w[users --skip-stimulus --skip-reflex]

    assert_no_file "../../tmp/app/javascript/controllers/users_controller.js"
    assert_no_file "../../tmp/app/reflexes/users_reflex.rb"
  end

  test "creates reflex with given reflex actions" do
    stub_entrypoint
    stub_bundler

    run_generator %w[User update do_stuff DoMoreStuff]

    assert_file "../../tmp/app/reflexes/user_reflex.rb" do |reflex|
      assert_instance_method :update, reflex
      assert_instance_method :do_stuff, reflex
      assert_instance_method :do_more_stuff, reflex
    end

    assert_file "../../tmp/app/javascript/controllers/user_controller.js" do |controller|
      assert_match(/beforeUpdate/, controller)
      assert_match(/updateSuccess/, controller)
      assert_match(/updateError/, controller)
      assert_match(/afterUpdate/, controller)
      assert_match(/beforeDoStuff/, controller)
      assert_match(/doStuffSuccess/, controller)
      assert_match(/doStuffError/, controller)
      assert_match(/afterDoStuff/, controller)
      assert_match(/beforeDoMoreStuff/, controller)
      assert_match(/doMoreStuffSuccess/, controller)
      assert_match(/doMoreStuffError/, controller)
      assert_match(/afterDoMoreStuff/, controller)
    end
  end
end
