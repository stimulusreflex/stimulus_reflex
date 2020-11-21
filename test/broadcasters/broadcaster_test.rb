require_relative "../test_helper"

class StimulusReflex::BroadcasterTest < ActiveSupport::TestCase
  setup do
    @reflex = Minitest::Mock.new
    @reflex.expect :stream_name, "TestStream"
  end

  test "raises a NotImplementedError if called directly" do
    broadcaster = StimulusReflex::Broadcaster.new(@reflex)

    assert_raises(NotImplementedError) { broadcaster.broadcast }
    assert_raises(NotImplementedError) { broadcaster.broadcast_message(subject: "Test") }
  end
end
