# frozen_string_literal: true

require_relative "broadcaster_test_case"

class StimulusReflex::BroadcasterTest < StimulusReflex::BroadcasterTestCase
  test "raises a NotImplementedError if called directly" do
    broadcaster = StimulusReflex::Broadcaster.new(@reflex)

    assert_raises(NotImplementedError) { broadcaster.broadcast }
  end
end
