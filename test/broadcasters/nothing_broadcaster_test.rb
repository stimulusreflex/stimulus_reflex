# frozen_string_literal: true

require_relative "broadcaster_test_case"

class StimulusReflex::NothingBroadcasterTest < StimulusReflex::BroadcasterTestCase
  test "broadcasts a nothing morph when called" do
    broadcaster = StimulusReflex::NothingBroadcaster.new(@reflex)

    expected = {
      "cableReady" => true,
      "operations" => [
        {
          "name" => "stimulus-reflex:morph-nothing",
          "selector" => nil,
          "payload" => {},
          "stimulusReflex" => {
            "some" => "data",
            "morph" => "nothing"
          },
          "reflexId" => "666",
          "operation" => "dispatchEvent"
        }
      ]
    }

    assert_broadcast_on @reflex.stream_name, expected do
      broadcaster.broadcast nil, {some: :data}
    end
  end
end
