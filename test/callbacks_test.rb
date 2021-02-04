# frozen_string_literal: true

require_relative "test_helper"

class StimulusReflex::CallbacksTest < ActiveSupport::TestCase
  class TestReflex
    include StimulusReflex::Callbacks

    attr_reader :before_unless, :before_if

    before_reflex :do_stuff_unless, unless: -> { 1.zero? }
    before_reflex :do_stuff_if, if: -> { 1.zero? }

    def initialize
      @before_unless = false
      @before_if = false
    end

    def process
      run_callbacks(:process)
    end

    def do_stuff_unless
      @before_unless = true
    end

    def do_stuff_if
      @before_if = true
    end
  end

  setup do
    @reflex = TestReflex.new
  end

  test "it processes callbacks correctly" do
    @reflex.process

    assert @reflex.before_unless
    refute @reflex.before_if
  end
end
