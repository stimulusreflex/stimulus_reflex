# frozen_string_literal: true

require_relative "test_helper"

class StimulusReflex::ReflexFactoryTest < ActionCable::Channel::TestCase
  tests StimulusReflex::Channel

  test "reflex class needs to be an ancestor of StimulusReflex::Reflex" do
    exception = assert_raises(NameError) { StimulusReflex::ReflexFactory.new(subscribe, {target: "Object#inspect"}).call }
    assert_includes exception.message.force_encoding("utf-8"), "uninitialized constant ObjectReflex"

    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new(subscribe, {target: "NoReflex#no_reflex"}).call }
    assert_equal "NoReflex is not a StimulusReflex::Reflex", exception.message

    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new(subscribe, {target: "No#no_reflex"}).call }
    assert_equal "NoReflex is not a StimulusReflex::Reflex", exception.message
  end

  test "doesn't raise if owner of method is ancestor of reflex class and descendant of StimulusReflex::Reflex" do
    assert_nothing_raised { StimulusReflex::ReflexFactory.new(subscribe, {version: StimulusReflex::VERSION, target: "ApplicationReflex#default_reflex"}).call }
    assert_nothing_raised { StimulusReflex::ReflexFactory.new(subscribe, {version: StimulusReflex::VERSION, target: "ApplicationReflex#application_reflex"}).call }

    assert_nothing_raised { StimulusReflex::ReflexFactory.new(subscribe, {version: StimulusReflex::VERSION, target: "PostReflex#default_reflex"}).call }
    assert_nothing_raised { StimulusReflex::ReflexFactory.new(subscribe, {version: StimulusReflex::VERSION, target: "PostReflex#application_reflex"}).call }
    assert_nothing_raised { StimulusReflex::ReflexFactory.new(subscribe, {version: StimulusReflex::VERSION, target: "PostReflex#post_reflex"}).call }

    assert_nothing_raised { StimulusReflex::ReflexFactory.new(subscribe, {version: StimulusReflex::VERSION, target: "CounterReflex#default_reflex"}).call }
    assert_nothing_raised { StimulusReflex::ReflexFactory.new(subscribe, {version: StimulusReflex::VERSION, target: "CounterReflex#application_reflex"}).call }
    assert_nothing_raised { StimulusReflex::ReflexFactory.new(subscribe, {version: StimulusReflex::VERSION, target: "CounterReflex#increment"}).call }
  end

  test "raises if method is not owned by a descendant of StimulusReflex::Reflex" do
    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new(subscribe, {target: "ApplicationReflex#itself"}).call }
    assert_equal "Reflex method 'itself' is not defined on class 'ApplicationReflex' or on any of its ancestors", exception.message

    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new(subscribe, {target: "ApplicationReflex#itself"}).call }
    assert_equal "Reflex method 'itself' is not defined on class 'ApplicationReflex' or on any of its ancestors", exception.message

    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new(subscribe, {target: "PostReflex#itself"}).call }
    assert_equal "Reflex method 'itself' is not defined on class 'PostReflex' or on any of its ancestors", exception.message

    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new(subscribe, {target: "PostReflex#binding"}).call }
    assert_equal "Reflex method 'binding' is not defined on class 'PostReflex' or on any of its ancestors", exception.message

    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new(subscribe, {target: "PostReflex#byebug"}).call }
    assert_equal "Reflex method 'byebug' is not defined on class 'PostReflex' or on any of its ancestors", exception.message

    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new(subscribe, {target: "PostReflex#debug"}).call }
    assert_equal "Reflex method 'debug' is not defined on class 'PostReflex' or on any of its ancestors", exception.message

    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new(subscribe, {target: "ApplicationReflex#post_reflex"}).call }
    assert_equal "Reflex method 'post_reflex' is not defined on class 'ApplicationReflex' or on any of its ancestors", exception.message
  end

  test "raises if method is a private method" do
    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new(subscribe, {target: "ApplicationReflex#private_application_reflex"}).call }
    assert_equal "Reflex method 'private_application_reflex' is not defined on class 'ApplicationReflex' or on any of its ancestors", exception.message

    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new(subscribe, {target: "PostReflex#private_application_reflex"}).call }
    assert_equal "Reflex method 'private_application_reflex' is not defined on class 'PostReflex' or on any of its ancestors", exception.message

    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new(subscribe, {target: "PostReflex#private_post_reflex"}).call }
    assert_equal "Reflex method 'private_post_reflex' is not defined on class 'PostReflex' or on any of its ancestors", exception.message

    exception = assert_raises(ArgumentError) { StimulusReflex::ReflexFactory.new(subscribe, {target: "CounterReflex#private_post_reflex"}).call }
    assert_equal "Reflex method 'private_post_reflex' is not defined on class 'CounterReflex' or on any of its ancestors", exception.message
  end

  test "safe_ancestors" do
    reflex_factory = StimulusReflex::ReflexFactory.new(subscribe, {target: "ApplicationReflex#default_reflex"})
    assert_equal [ApplicationReflex, StimulusReflex::CableReadiness], reflex_factory.send(:safe_ancestors)

    reflex_factory = StimulusReflex::ReflexFactory.new(subscribe, {target: "PostReflex#default_reflex"})
    assert_equal [PostReflex, ApplicationReflex, StimulusReflex::CableReadiness], reflex_factory.send(:safe_ancestors)

    reflex_factory = StimulusReflex::ReflexFactory.new(subscribe, {target: "CounterReflex#increment"})
    assert_equal [CounterReflex, CounterConcern, ApplicationReflex, StimulusReflex::CableReadiness], reflex_factory.send(:safe_ancestors)
  end
end
