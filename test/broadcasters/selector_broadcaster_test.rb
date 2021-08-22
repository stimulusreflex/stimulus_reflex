# frozen_string_literal: true

require_relative "broadcaster_test_case"

module StimulusReflex
  class SelectorBroadcasterTest < StimulusReflex::BroadcasterTestCase
    test "morphs the contents of an element if the selector(s) are present in both original and morphed html fragments" do
      broadcaster = StimulusReflex::SelectorBroadcaster.new(@reflex)
      broadcaster.append_morph("#foo", '<div id="foo"><div>bar</div><div>baz</div></div>')

      expected = {
        "cableReady" => true,
        "operations" => [
          {
            "selector" => "#foo",
            "html" => "<div>bar</div><div>baz</div>",
            "payload" => {},
            "childrenOnly" => true,
            "permanentAttributeName" => nil,
            "stimulusReflex" => {
              "some" => "data",
              "morph" => "selector"
            },
            "reflexId" => "666",
            "operation" => "morph"
          }
        ]
      }

      assert_broadcast_on @reflex.stream_name, expected do
        broadcaster.broadcast nil, some: :data
      end
    end

    test "replaces the contents of an element and ignores permanent-attributes if the selector(s) aren't present in the replacing html fragment" do
      broadcaster = StimulusReflex::SelectorBroadcaster.new(@reflex)
      broadcaster.append_morph("#foo", '<div id="baz"><span>bar</span></div>')

      expected = {
        "cableReady" => true,
        "operations" => [
          {
            "selector" => "#foo",
            "html" => '<div id="baz"><span>bar</span></div>',
            "payload" => {},
            "stimulusReflex" => {
              "some" => "data",
              "morph" => "selector"
            },
            "reflexId" => "666",
            "operation" => "innerHtml"
          }
        ]
      }

      assert_broadcast_on @reflex.stream_name, expected do
        broadcaster.broadcast nil, some: :data
      end
    end

    test "morphs the contents of an element to an empty string if no content specified" do
      broadcaster = StimulusReflex::SelectorBroadcaster.new(@reflex)
      broadcaster.append_morph("#foo", nil)

      expected = {
        "cableReady" => true,
        "operations" => [
          {
            "selector" => "#foo",
            "html" => "",
            "payload" => {},
            "stimulusReflex" => {
              "some" => "data",
              "morph" => "selector"
            },
            "reflexId" => "666",
            "operation" => "innerHtml"
          }
        ]
      }

      assert_broadcast_on @reflex.stream_name, expected do
        broadcaster.broadcast nil, some: :data
      end
    end

    test "morphs the contents of an element to an empty string if empty specified" do
      broadcaster = StimulusReflex::SelectorBroadcaster.new(@reflex)
      broadcaster.append_morph("#foo", "")

      expected = {
        "cableReady" => true,
        "operations" => [
          {
            "selector" => "#foo",
            "html" => "",
            "payload" => {},
            "stimulusReflex" => {
              "some" => "data",
              "morph" => "selector"
            },
            "reflexId" => "666",
            "operation" => "innerHtml"
          }
        ]
      }

      assert_broadcast_on @reflex.stream_name, expected do
        broadcaster.broadcast nil, some: :data
      end
    end

    test "morphs the contents of an element to an empty string if no content specified, hash form" do
      broadcaster = StimulusReflex::SelectorBroadcaster.new(@reflex)
      broadcaster.append_morph({"#foo": nil}, nil)

      expected = {
        "cableReady" => true,
        "operations" => [
          {
            "selector" => "#foo",
            "html" => "",
            "payload" => {},
            "stimulusReflex" => {
              "some" => "data",
              "morph" => "selector"
            },
            "reflexId" => "666",
            "operation" => "innerHtml"
          }
        ]
      }

      assert_broadcast_on @reflex.stream_name, expected do
        broadcaster.broadcast nil, some: :data
      end
    end

    test "morphs the contents of an element to specified HTML, hash form" do
      broadcaster = StimulusReflex::SelectorBroadcaster.new(@reflex)
      broadcaster.append_morph({"#foo": '<div id="foo"><div>bar</div><div>baz</div></div>'}, nil)

      expected = {
        "cableReady" => true,
        "operations" => [
          {
            "selector" => "#foo",
            "html" => "<div>bar</div><div>baz</div>",
            "payload" => {},
            "childrenOnly" => true,
            "permanentAttributeName" => nil,
            "stimulusReflex" => {
              "some" => "data",
              "morph" => "selector"
            },
            "reflexId" => "666",
            "operation" => "morph"
          }
        ]
      }

      assert_broadcast_on @reflex.stream_name, expected do
        broadcaster.broadcast nil, some: :data
      end
    end
  end
end
