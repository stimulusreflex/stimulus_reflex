require_relative "../test_helper"

class StimulusReflex::SelectorBroadcasterTest < ActiveSupport::TestCase
  setup do
    @reflex = Minitest::Mock.new
    @reflex.expect :stream_name, "TestStream"
    @reflex.expect :permanent_attribute_name, "some-attribute"
  end

  test "morphs the contents of an element if the selector(s) are present in both original and morphed html fragments" do
    broadcaster = StimulusReflex::SelectorBroadcaster.new(@reflex)

    cable_ready_channels = Minitest::Mock.new
    cable_ready_channel = Minitest::Mock.new
    fragment = Minitest::Mock.new
    match = Minitest::Mock.new
    Nokogiri::HTML.stub :fragment, fragment do
      fragment.expect(:at_css, match, ["#foo"])
      match.expect(:present?, true)

      # we need to mock `!`, because `blank?` returns
      # respond_to?(:empty?) ? !!empty? : !self
      match.expect(:!, false)
      match.expect(:inner_html, "<span>bar</span>")
      CableReady::Channels.stub :instance, cable_ready_channels do
        broadcaster.append_morph("#foo", "<div id=\"foo\"><span>bar</span></div>")
        cable_ready_channel.expect(:morph, nil, [{
          selector: "#foo",
          html: "<span>bar</span>",
          children_only: true,
          permanent_attribute_name: "some-attribute",
          stimulus_reflex: {
            some: :data,
            morph: :selector
          }
        }])
        cable_ready_channels.expect(:[], cable_ready_channel, ["TestStream"])
        cable_ready_channels.expect(:broadcast, nil)

        broadcaster.broadcast(nil, {some: :data})
      end
    end

    assert_mock cable_ready_channels
    assert_mock cable_ready_channel
  end
end
