require "test_helper"

class StimulusReflexGeneratorTest < Rails::Generators::TestCase
  tests StimulusReflex::Generators::StimulusReflexGenerator
  destination File.expand_path("../../tmp", __FILE__)
  setup :prepare_destination

  test "creates named controller and reflex files" do
    run_generator %w[test]
    assert_file "app/javascript/controllers/application_controller.js"
    assert_file "app/javascript/controllers/test_controller.js"
    assert_file "app/reflexes/application_reflex.rb"
    assert_file "app/reflexes/test_reflex.rb", /TestReflex/
  end

  test "will not create files unless name is passed" do
    run_generator
    assert_no_file "app/javascript/controllers/application_controller.js"
    assert_no_file "app/javascript/controllers/test_controller.js"
    assert_no_file "app/reflexes/application_reflex.rb"
    assert_no_file "app/reflexes/example_reflex.rb"
  end
end
