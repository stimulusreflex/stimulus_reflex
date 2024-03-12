# frozen_string_literal: true

require_relative "test_helper"

class StimulusReflex::ReflexFactoryTest < ActionCable::Channel::TestCase
  tests StimulusReflex::Channel

  test "reflex class needs to be an ancestor of StimulusReflex::Reflex" do
    exception = assert_raises(NameError) { StimulusReflex::ReflexFactory.new("Object#inspect").call }
    assert_equal "uninitialized constant ObjectReflex Did you mean? ObjectSpace", exception.message.squish

    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new("NoReflex#no_reflex").call }
    assert_equal "NoReflex is not a StimulusReflex::Reflex", exception.message

    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new("No#no_reflex").call }
    assert_equal "NoReflex is not a StimulusReflex::Reflex", exception.message
  end

  test "doesn't raise if owner of method is ancestor of reflex class and descendant of StimulusReflex::Reflex" do
    assert_nothing_raised { StimulusReflex::ReflexFactory.new("ApplicationReflex#default_reflex").call }
    assert_nothing_raised { StimulusReflex::ReflexFactory.new("ApplicationReflex#application_reflex").call }

    assert_nothing_raised { StimulusReflex::ReflexFactory.new("PostReflex#default_reflex").call }
    assert_nothing_raised { StimulusReflex::ReflexFactory.new("PostReflex#application_reflex").call }
    assert_nothing_raised { StimulusReflex::ReflexFactory.new("PostReflex#post_reflex").call }

    assert_nothing_raised { StimulusReflex::ReflexFactory.new("CounterReflex#default_reflex").call }
    assert_nothing_raised { StimulusReflex::ReflexFactory.new("CounterReflex#application_reflex").call }
    assert_nothing_raised { StimulusReflex::ReflexFactory.new("CounterReflex#increment").call }
  end

  test "raises if method is not owned by a descendant of StimulusReflex::Reflex" do
    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new("ApplicationReflex#itself").call }
    assert_equal "Reflex method 'itself' is not defined on class 'ApplicationReflex' or on any of its ancestors", exception.message

    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new("ApplicationReflex#itself").call }
    assert_equal "Reflex method 'itself' is not defined on class 'ApplicationReflex' or on any of its ancestors", exception.message

    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new("PostReflex#itself").call }
    assert_equal "Reflex method 'itself' is not defined on class 'PostReflex' or on any of its ancestors", exception.message

    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new("PostReflex#binding").call }
    assert_equal "Reflex method 'binding' is not defined on class 'PostReflex' or on any of its ancestors", exception.message

    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new("PostReflex#byebug").call }
    assert_equal "Reflex method 'byebug' is not defined on class 'PostReflex' or on any of its ancestors", exception.message

    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new("PostReflex#debug").call }
    assert_equal "Reflex method 'debug' is not defined on class 'PostReflex' or on any of its ancestors", exception.message

    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new("ApplicationReflex#post_reflex").call }
    assert_equal "Reflex method 'post_reflex' is not defined on class 'ApplicationReflex' or on any of its ancestors", exception.message
  end

  test "raises if method is a private method" do
    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new("ApplicationReflex#private_application_reflex").call }
    assert_equal "Reflex method 'private_application_reflex' is not defined on class 'ApplicationReflex' or on any of its ancestors", exception.message

    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new("PostReflex#private_application_reflex").call }
    assert_equal "Reflex method 'private_application_reflex' is not defined on class 'PostReflex' or on any of its ancestors", exception.message

    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new("PostReflex#private_post_reflex").call }
    assert_equal "Reflex method 'private_post_reflex' is not defined on class 'PostReflex' or on any of its ancestors", exception.message

    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new("CounterReflex#private_post_reflex").call }
    assert_equal "Reflex method 'private_post_reflex' is not defined on class 'CounterReflex' or on any of its ancestors", exception.message
  end

  test "safe_ancestors" do
    reflex_factory = StimulusReflex::ReflexFactory.new("ApplicationReflex#default_reflex")
    assert_equal [ApplicationReflex], reflex_factory.send(:safe_ancestors)

    reflex_factory = StimulusReflex::ReflexFactory.new("PostReflex#default_reflex")
    assert_equal [PostReflex, ApplicationReflex], reflex_factory.send(:safe_ancestors)

    reflex_factory = StimulusReflex::ReflexFactory.new("CounterReflex#increment")
    assert_equal [CounterReflex, CounterConcern, ApplicationReflex], reflex_factory.send(:safe_ancestors)
  end
end
