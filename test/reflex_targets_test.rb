# frozen_string_literal: true

require_relative "test_helper"
require "mocha/minitest"

class StimulusReflex::ReflexTargetsTest < ActionCable::Channel::TestCase
  tests StimulusReflex::Channel

  attr_reader :reflex
  delegate :post_targets, :button_target, :absent_target, :unicorn_targets, :cable_ready, to: :reflex

  setup do
    stub_connection(session_id: SecureRandom.uuid)
    def connection.env
      @env ||= {}
    end

    @element = StimulusReflex::Element.new({}, selector: "/html/body/button[1]")
    @reflex = build_with_targets
  end

  def build_with_targets(targets_data: nil, target_scope: "page")
    targets_data ||= {
      "post" => [
        { "name" => "post", "selector" => "/html/body/div[1]", "attrs" => { "class" => "" } },
        { "name" => "post", "selector" => "/html/body/div[2]", "attrs" => { "class" => "special" } },
        { "name" => "post", "selector" => "/html/body/div[3]", "attrs" => { "class" => "special" } }
      ],
      "button" => [
        { "name" => "button", "selector" => "/html/body/button[1]", "dataset" => {} }
      ]
    }

    reflex_data = StimulusReflex::ReflexData.new(
      element: @element,
      url: "https://test.stimulusreflex.com",
      targets: targets_data,
      id: "123",
      version: StimulusReflex::VERSION,
      reflex_controller: "stimulus-reflex",
      target_scope: target_scope
    )

    StimulusReflex::Reflex.new(subscribe, reflex_data: reflex_data)
  end

  def build_payload(operations = [])
    {
      "cableReady" => true,
      "operations" => Array.wrap(operations),
      "version" => CableReady::VERSION
    }
  end

  test "shares a cable_ready instance with targets and target collections" do
    assert_equal reflex.cable_ready, button_target.cable_ready
    assert_equal reflex.cable_ready, post_targets.cable_ready
    assert_equal reflex.cable_ready, post_targets.first.cable_ready
  end

  test "builds chainable operations on a (singular) target" do
    expected = build_payload(
      [
        {"selector" => "/html/body/button[1]", "xpath" => true, "name" => "updated", "reflexId" => "123", "operation" => "addCssClass"},
        {"selector" => "/html/body/button[1]", "xpath" => true, "text" => "Button", "reflexId" => "123", "operation" => "textContent"}
      ]
    )

    assert_broadcast_on(reflex.stream_name, expected) do
      button_target.add_css_class(name: "updated").text_content(text: "Button")

      reflex.cable_ready.broadcast
    end
  end

  test "builds chainable operations on (plural) multi-target collection using select_all" do
    expected = build_payload(
      [
        {"selector" => "[data-reflex-target='post']", "selectAll" => true, "name" => "updated", "reflexId" => "123", "operation" => "addCssClass"},
        {"selector" => "[data-reflex-target='post']", "selectAll" => true, "text" => "Post", "reflexId" => "123", "operation" => "textContent"}
      ]
    )

    assert_broadcast_on(reflex.stream_name, expected) do
      post_targets.add_css_class(name: "updated").text_content(text: "Post")

      reflex.cable_ready.broadcast
    end
  end

  test "target collections respond to array-like interface" do
    assert_equal post_targets.any?, true
    assert_equal post_targets.many?, true
    assert_equal post_targets.count, 3
    assert_equal post_targets.first.selector, "/html/body/div[1]"
    assert_equal post_targets.last.selector, "/html/body/div[3]"

    special_targets = post_targets.select{ |target| target.attrs[:class].include?("special") }

    assert_equal special_targets.count, 2
    assert_equal special_targets.first.selector, "/html/body/div[2]"
    assert_equal special_targets.last.selector, "/html/body/div[3]"
  end

  test "doesn't raise an exception / halt execution if operation(s) are called on a missing target" do
    expected = build_payload(
      [
        {"selector" => "/html/body/button[1]", "xpath" => true, "name" => "success", "reflexId" => "123", "operation" => "addCssClass"},
        {"selector" => "/html/body/button[1]", "xpath" => true, "text" => "I'm still updated!", "reflexId" => "123", "operation" => "textContent"}
      ]
    )

    assert_broadcast_on(reflex.stream_name, expected) do
      absent_target.add_css_class(name: "nope").text_content(text: "I'm not even here!")
      button_target.add_css_class(name: "success").text_content(text: "I'm still updated!")

      reflex.cable_ready.broadcast
    end
  end

  test "missing/undefined targets that *might* exist but are currently not in the DOM still respond to inspection" do
    assert_equal absent_target.any?, false
    assert_equal absent_target.present?, false
    assert_equal unicorn_targets.count, 0
    assert_equal unicorn_targets.first.present?, false
    assert_equal unicorn_targets.any?, false
  end

  test "targets in a multi-target collection can also be operated on individually" do
    expected = build_payload(
      [
        {"selector" => "/html/body/div[2]", "xpath" => true, "name" => "upgrade", "reflexId" => "123", "operation" => "addCssClass"},
        {"selector" => "/html/body/div[3]", "xpath" => true, "name" => "upgrade", "reflexId" => "123", "operation" => "addCssClass"},
        {"selector" => "/html/body/div[1]", "xpath" => true, "name" => "downgrade", "reflexId" => "123", "operation" => "addCssClass"}
      ]
    )

    assert_broadcast_on(reflex.stream_name, expected) do
      post_targets
        .select{ |target| target.attrs[:class].include?("special") }
        .each{ |target| target.add_css_class(name: "upgrade") }

      post_targets
        .find{ |target| target.attrs[:class].blank? }
        .add_css_class(name: "downgrade")

      reflex.cable_ready.broadcast
    end
  end

  test "plays nicely with other operations interspersed" do
    expected = build_payload(
      [
        {"selector" => "[data-reflex-target='post']", "selectAll" => true, "name" => "hey", "reflexId" => "123", "operation" => "addCssClass"},
        {"selector" => "#other", "name" => "thing", "reflexId" => "123", "operation" => "addCssClass"},
        {"selector" => "[data-reflex-target='post']", "selectAll" => true, "text" => "I'm a Post", "reflexId" => "123", "operation" => "textContent"}
      ]
    )

    assert_broadcast_on(reflex.stream_name, expected) do
      post_targets.add_css_class(name: "hey")
      cable_ready.add_css_class(selector: "#other", name: "thing")
      post_targets.text_content(text: "I'm a Post")

      reflex.cable_ready.broadcast
    end
  end
end
