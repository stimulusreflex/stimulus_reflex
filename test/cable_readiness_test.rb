# frozen_string_literal: true

require_relative "test_helper"

class StimulusReflex::CableReadinessTest < ActiveSupport::TestCase
  test "can be prepended" do
    class MyReflexPrepended
      prepend StimulusReflex::CableReadiness

      def id
        "123"
      end

      def stream_name
        "123"
      end
    end

    reflex = MyReflexPrepended.new
    assert_includes reflex.methods, :cable_ready
  end
end
