require_relative "../test_helper"

class StimulusReflex::PageBroadcasterTest < ActiveSupport::TestCase
  setup do
    @reflex = Minitest::Mock.new
    @reflex.expect :params, {action: "show"}
    @reflex.expect :stream_name, "TestStream"
    @reflex.expect :permanent_attribute_name, "some-attribute"
  end

  test "returns if the response html is empty" do
    controller = Minitest::Mock.new
    controller.expect(:process, nil, ["show"])
    @reflex.expect :controller, controller
    @reflex.expect :controller, controller

    # stub the controller response with a struct responding to :body
    controller.expect(:response, Struct.new(:body).new(nil))

    broadcaster = StimulusReflex::PageBroadcaster.new(@reflex)

    cable_ready_channels = Minitest::Mock.new
    cable_ready_channels.expect(:broadcast, nil)

    broadcaster.broadcast(["#foo"], {some: :data})

    assert_raises { cable_ready_channels.verify }
  end

  test "performs a page morph given an array of reflex root selectors" do
    controller = Minitest::Mock.new
    controller.expect(:process, nil, ["show"])
    @reflex.expect :controller, controller
    @reflex.expect :controller, controller

    # stub the controller response with a struct responding to :body
    controller.expect(:response, Struct.new(:body).new("<html></html>"))

    broadcaster = StimulusReflex::PageBroadcaster.new(@reflex)

    cable_ready_channels = Minitest::Mock.new
    cable_ready_channel = Minitest::Mock.new
    document = Minitest::Mock.new
    Nokogiri::HTML.stub :parse, document do
      document.expect(:css, "something that is present", ["#foo"])
      document.expect(:css, Struct.new(:inner_html).new("<span>bar</span>"), ["#foo"])

      CableReady::Channels.stub :instance, cable_ready_channels do
        cable_ready_channel.expect(:morph, nil, [{
          selector: "#foo",
          html: "<span>bar</span>",
          children_only: true,
          permanent_attribute_name: "some-attribute",
          stimulus_reflex: {
            some: :data,
            morph: :page
          }
        }])
        cable_ready_channels.expect(:[], cable_ready_channel, ["TestStream"])
        cable_ready_channels.expect(:broadcast, nil)

        broadcaster.broadcast(["#foo"], {some: :data})
      end
    end

    assert_mock cable_ready_channels
    assert_mock cable_ready_channel
  end
end
