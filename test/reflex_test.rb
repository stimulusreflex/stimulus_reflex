# frozen_string_literal: true

require_relative "test_helper"
require "mocha/minitest"

class StimulusReflex::ReflexTest < ActionCable::Channel::TestCase
  tests StimulusReflex::Channel

  setup do
    stub_connection(session_id: SecureRandom.uuid)
    def connection.env
      @env ||= {}
    end

    reflex_data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", id: "666", version: StimulusReflex::VERSION)
    @reflex = StimulusReflex::Reflex.new(subscribe, reflex_data: reflex_data)
    @reflex.controller_class.view_paths << Rails.root.join("test/views")
  end

  test "render plain" do
    assert @reflex.render(plain: "Some text") == "Some text"
  end

  test "render template" do
    assert @reflex.render("/hello_template", assigns: {message: "Testing 123"}) == "<p>Hello from template! Testing 123</p>\n"
  end

  test "render partial" do
    assert @reflex.render(partial: "/hello_partial", assigns: {message: "Testing 123"}) == "<p>Hello from partial! Testing 123</p>\n"
  end

  test "dom_id" do
    assert @reflex.dom_id(TestModel.new(id: 123)) == "#test_model_123"
  end

  test "params behave like ActionController::Parameters" do
    params = {"a" => "1", "b" => "2", "c" => "3"}
    reflex_data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", params: params, version: StimulusReflex::VERSION)
    reflex = StimulusReflex::Reflex.new(subscribe, reflex_data: reflex_data)
    deleted_param = reflex.params.delete("a")

    assert deleted_param == "1"
    assert reflex.params.to_unsafe_h == {"controller" => "test", "action" => "index", "b" => "2", "c" => "3"}
  end
end
