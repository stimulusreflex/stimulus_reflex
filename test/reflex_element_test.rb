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

    reflex_data = StimulusReflex::ReflexData.new(xpath_element: "/html/body/button[1]", url: "https://test.stimulusreflex.com", id: "666", version: StimulusReflex::VERSION)
    @reflex = StimulusReflex::Reflex.new(subscribe, reflex_data: reflex_data)
    @element = @reflex.element
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
      {"selector" => "/html/body/button[1]", "xpath" => true, "html" => "<p>Some HTML</p>", "reflexId" => "666", "operation" => "innerHtml"}
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
      {"selector" => "/html/body/button[1]", "xpath" => true, "html" => "<p>Some HTML</p>", "reflexId" => "666", "operation" => "innerHtml"},
      {"name" => "abc", "detail" => {"some" => "key"}, "reflexId" => "666", "selector" => "/html/body/button[1]", "xpath" => true, "operation" => "dispatchEvent"}
    ]

    assert_broadcast_on(@reflex.stream_name, expected) do
      @element.inner_html(html: "<p>Some HTML</p>").dispatch_event(name: "abc", detail: {some: "key"}).broadcast
    end
  end
end
