# frozen_string_literal: true

require_relative "test_helper"

class StimulusReflex::ConcernTest < ActiveSupport::TestCase
  module TestConcern
    extend ActiveSupport::Concern
    include StimulusReflex::ConcernEnhancer
  end

  class TestReflex < StimulusReflex::Reflex
    include TestConcern

    def initialize
    end
  end

  class TestController < ActionController::Base
    include TestConcern
  end

  class TestModel < ActiveRecord::Base
    include TestConcern
  end

  test "included in a reflex it stubs controller and model methods" do
    assert_nil TestReflex.helper_method
    assert_nil TestReflex.before_action
    assert_nil TestReflex.around_action
    assert_nil TestReflex.after_action

    assert_nil TestReflex.before_save
    assert_nil TestReflex.around_save
    assert_nil TestReflex.after_save

    refute_nil TestReflex.before_reflex
  end

  test "included in a controller it stubs reflex methods" do
    assert_nil TestController.before_reflex
    assert_nil TestController.around_reflex
    assert_nil TestController.after_reflex

    refute_nil TestController.before_action
  end

  test "included in a model it stubs reflex methods" do
    assert_nil TestModel.before_reflex
    assert_nil TestModel.around_reflex
    assert_nil TestModel.after_reflex

    refute_nil TestModel.after_save
  end
end
