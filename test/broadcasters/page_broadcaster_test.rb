# frozen_string_literal: true

require_relative "broadcaster_test_case"

class StimulusReflex::PageBroadcasterTest < StimulusReflex::BroadcasterTestCase
  test "returns if the response html is empty" do
    broadcaster = StimulusReflex::PageBroadcaster.new(@reflex)
    broadcaster.broadcast(["#foo"], {some: :data})
    # TODO: figure out how to refute_broadcast_on
  end

  test "performs a page morph on body" do
    class << @reflex.controller.response
      def body
        "<html><head></head><body>New Content</body></html>"
      end
    end

    broadcaster = StimulusReflex::PageBroadcaster.new(@reflex)

    expected = {
      "cableReady" => true,
      "operations" => {
        "morph" => [
          {
            "selector" => "body",
            "html" => "New Content",
            "childrenOnly" => true,
            "permanentAttributeName" => nil,
            "stimulusReflex" => {
              "some" => :data,
              "morph" => :page
            }
          }
        ]
      }
    }

    assert_broadcast_on @reflex.stream_name, expected do
      broadcaster.broadcast(["body"], {some: :data})
    end
  end

  test "performs a page morph given an array of reflex root selectors" do
    class << @reflex.controller.response
      def body
        "<html><head></head><body><div id=\"foo\">New Content</div></body></html>"
      end
    end

    broadcaster = StimulusReflex::PageBroadcaster.new(@reflex)

    expected = {
      "cableReady" => true,
      "operations" => {
        "morph" => [
          {
            "selector" => "#foo",
            "html" => "New Content",
            "childrenOnly" => true,
            "permanentAttributeName" => nil,
            "stimulusReflex" => {
              "some" => :data,
              "morph" => :page
            }
          }
        ]
      }
    }

    assert_broadcast_on @reflex.stream_name, expected do
      broadcaster.broadcast(["#foo"], {some: :data})
    end
  end
end
