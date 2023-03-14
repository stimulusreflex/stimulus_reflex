# frozen_string_literal: true

require_relative "test_helper"
require "mocha/minitest"

class StimulusReflex::ReflexElementTest < ActionCable::Channel::TestCase
  tests StimulusReflex::Channel

  setup do
    stub_connection(session_id: SecureRandom.uuid)
    def connection.env
      @env ||= {}
    end

    @element = StimulusReflex::Element.new({}, selector: "#element-selector")

    @reflex = StimulusReflex::Reflex.new(subscribe, url: "https://test.stimulusreflex.com", client_attributes: {id: "666", version: StimulusReflex::VERSION})
    @cable_ready = StimulusReflex::CableReadyChannels.new(@reflex)
    @element.cable_ready = @cable_ready
  end

  def build_payload(operations = [])
    {
      "cableReady" => true,
      "operations" => Array.wrap(operations),
      "version" => CableReady::VERSION
    }
  end

  test "broadcasts updates using element.broadcast" do
    expected = build_payload(
      {"selector" => "#element-selector", "xpath" => false, "html" => "<p>Some HTML</p>", "reflexId" => "666", "operation" => "innerHtml"}
    )

    assert_broadcast_on(@reflex.stream_name, expected) do
      @element.inner_html(html: "<p>Some HTML</p>")
      @element.broadcast
    end
  end

  test "selector can be overwritten" do
    expected = build_payload(
      {"selector" => "#overwritten", "xpath" => false, "html" => "<p>Some HTML</p>", "reflexId" => "666", "operation" => "innerHtml"}
    )

    assert_broadcast_on(@reflex.stream_name, expected) do
      @element.inner_html(html: "<p>Some HTML</p>", selector: "#overwritten").broadcast
    end
  end

  test "broadcasts using element.broadcast chained" do
    expected = build_payload [
      {"selector" => "#element-selector", "xpath" => false, "html" => "<p>Some HTML</p>", "reflexId" => "666", "operation" => "innerHtml"},
      {"name" => "abc", "detail" => {"some" => "key"}, "reflexId" => "666", "selector" => "#element-selector", "operation" => "dispatchEvent"}
    ]

    assert_broadcast_on(@reflex.stream_name, expected) do
      @element.inner_html(html: "<p>Some HTML</p>").dispatch_event(name: "abc", detail: {some: "key"}).broadcast
    end
  end
end
