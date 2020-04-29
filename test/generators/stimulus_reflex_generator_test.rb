# frozen_string_literal: true

require "rails/generators/test_case"
require_relative "../test_helper"

class StimulusReflexGeneratorTest < Rails::Generators::TestCase
  tests StimulusReflexGenerator
  destination File.expand_path("../../tmp", __FILE__)
  setup :prepare_destination

  test "creates singular named controller and reflex files" do
    run_generator %w[demo]
    assert_file "app/javascript/controllers/application_controller.js"
    assert_file "app/javascript/controllers/demo_controller.js", /DemoReflex/
    assert_file "app/reflexes/application_reflex.rb"
    assert_file "app/reflexes/demo_reflex.rb", /DemoReflex/
  end

  test "creates plural named controller and reflex files" do
    run_generator %w[posts]
    assert_file "app/javascript/controllers/application_controller.js"
    assert_file "app/javascript/controllers/posts_controller.js", /PostsReflex/
    assert_file "app/reflexes/application_reflex.rb"
    assert_file "app/reflexes/posts_reflex.rb", /PostsReflex/
  end
end
