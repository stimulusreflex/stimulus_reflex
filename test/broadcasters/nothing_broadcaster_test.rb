# frozen_string_literal: true

require_relative "broadcaster_test_case"

class StimulusReflex::NothingBroadcasterTest < StimulusReflex::BroadcasterTestCase
  test "broadcasts a server message when called" do
    broadcaster = StimulusReflex::NothingBroadcaster.new(@reflex)

    expected = {
      "cableReady" => true,
      "operations" => {
        "dispatchEvent" => [
          {
            "name" => "stimulus-reflex:server-message",
            "detail" => {
              "reflexId" => "666",
              "payload" => {},
              "stimulusReflex" => {
                "some" => :data,
                "morph" => :nothing,
                "serverMessage" => {
                  "subject" => "nothing",
                  "body" => nil
                }
              }
            },
            "reflexId" => "666"
          }
        ]
      }
    }

    assert_broadcast_on @reflex.stream_name, expected do
      broadcaster.broadcast nil, {some: :data, "reflexId" => "666"}
    end
  end
end
