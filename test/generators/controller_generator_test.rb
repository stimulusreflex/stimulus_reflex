require "test_helper"

class ControllerGeneratorTest < Rails::Generators::TestCase
  tests StimulusReflex::Generators::ControllerGenerator
  destination File.expand_path("../../tmp", __FILE__)
  setup :prepare_destination

  test "creates named controller files" do
    run_generator %w[test]
    assert_file "app/javascript/controllers/application_controller.js"
    assert_file "app/javascript/controllers/test_controller.js"
  end

  test "will not create files unless name is passed" do
    run_generator
    assert_no_file "app/javascript/controllers/"
  end
end
