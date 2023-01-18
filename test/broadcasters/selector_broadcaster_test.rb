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
        ],
        "version" => CableReady::VERSION
      }

      assert_broadcast_on @reflex.stream_name, expected do
        broadcaster.broadcast nil, some: :data
      end
    end

    test "morphs the contents of the body element" do
      broadcaster = StimulusReflex::SelectorBroadcaster.new(@reflex)
      broadcaster.append_morph("body", "<body><div><div>bar</div><div>baz</div></div></body>")

      expected = {
        "cableReady" => true,
        "operations" => [
          {
            "selector" => "body",
            "html" => "<div><div>bar</div><div>baz</div></div>",
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
        ],
        "version" => CableReady::VERSION
      }

      assert_broadcast_on @reflex.stream_name, expected do
        broadcaster.broadcast nil, some: :data
      end
    end

    test "morphs the contents of the html element" do
      broadcaster = StimulusReflex::SelectorBroadcaster.new(@reflex)
      broadcaster.append_morph("html", "<html><head><title>Test</title></head><body><div><div>bar</div><div>baz</div></div></body></html>")

      expected = {
        "cableReady" => true,
        "operations" => [
          {
            "selector" => "html",
            # Nokogiri automatically adds a `<meta>` tag for the encoding
            # See. https://github.com/sparklemotion/nokogiri/blob/6ea1449926ce97648bb2f7401c9e4fdcb0e261ba/lib/nokogiri/html4/document.rb#L34-L35
            "html" => "<head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"><title>Test</title></head><body><div><div>bar</div><div>baz</div></div></body>",
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
        ],
        "version" => CableReady::VERSION
      }

      assert_broadcast_on @reflex.stream_name, expected do
        broadcaster.broadcast nil, some: :data
      end
    end

    test "morphs the contents of the head element" do
      broadcaster = StimulusReflex::SelectorBroadcaster.new(@reflex)
      broadcaster.append_morph("head", "<head><title>Test</title></head>")

      expected = {
        "cableReady" => true,
        "operations" => [
          {
            "selector" => "head",
            "html" => "<title>Test</title>",
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
        ],
        "version" => CableReady::VERSION
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
        ],
        "version" => CableReady::VERSION
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
        ],
        "version" => CableReady::VERSION
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
        ],
        "version" => CableReady::VERSION
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
        ],
        "version" => CableReady::VERSION
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
        ],
        "version" => CableReady::VERSION
      }

      assert_broadcast_on @reflex.stream_name, expected do
        broadcaster.broadcast nil, some: :data
      end
    end
  end
end
