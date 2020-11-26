require_relative "../test_helper"

class StimulusReflex::NothingBroadcasterTest < ActiveSupport::TestCase
  setup do
    @reflex = Minitest::Mock.new
    @reflex.expect :stream_name, "TestStream"
  end

  test "broadcasts a server message when called" do
    broadcaster = StimulusReflex::NothingBroadcaster.new(@reflex)

    cable_ready_channels = Minitest::Mock.new
    cable_ready_channel = Minitest::Mock.new
    CableReady::Channels.stub :instance, cable_ready_channels do
      cable_ready_channel.expect(:dispatch_event, nil, [{name: "stimulus-reflex:server-message",
                                                         detail: {
                                                           reflexId: nil,
                                                           stimulus_reflex: {
                                                             some: :data,
                                                             morph: :nothing,
                                                             server_message: {
                                                               subject: "nothing", body: nil
                                                             }
                                                           }
                                                         }}])
      cable_ready_channels.expect(:[], cable_ready_channel, ["TestStream"])
      cable_ready_channels.expect(:broadcast, nil)
      broadcaster.broadcast(nil, {some: :data})
    end

    assert_mock cable_ready_channels
    assert_mock cable_ready_channel
  end
end
