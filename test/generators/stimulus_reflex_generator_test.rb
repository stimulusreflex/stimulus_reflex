# frozen_string_literal: true

require "rails/generators/test_case"
require_relative "../test_helper"

class StimulusReflexGeneratorTest < Rails::Generators::TestCase
  tests StimulusReflexGenerator
  destination File.expand_path("../../tmp", __FILE__)
  setup :prepare_destination

  test "creates named controller and reflex files" do
    run_generator %w[demo]
    assert_file "app/javascript/controllers/application_controller.js"
    assert_file "app/javascript/controllers/demo_controller.js", /DemoReflex/
    assert_file "app/reflexes/application_reflex.rb"
    assert_file "app/reflexes/demo_reflex.rb", /DemoReflex/
  end
end
