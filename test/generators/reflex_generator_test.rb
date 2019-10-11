require "test_helper"

class ReflexGeneratorTest < Rails::Generators::TestCase
  tests StimulusReflex::Generators::ReflexGenerator
  destination File.expand_path("../../tmp", __FILE__)
  setup :prepare_destination

  test "creates named reflex files" do
    run_generator %w[test]
    assert_file "app/reflexes/application_reflex.rb"
    assert_file "app/reflexes/test_reflex.rb", /TestReflex/
  end

  test "will not create files unless name is passed" do
    run_generator
    assert_no_file "app/reflexes/"
  end
end
