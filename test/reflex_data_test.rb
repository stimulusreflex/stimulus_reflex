# frozen_string_literal: true

require_relative "test_helper"

class StimulusReflex::ReflexDataTest < ActiveSupport::TestCase
  reflex_data = StimulusReflex::ReflexData.new({
    "params" => {
      "user" => {"email" => "test@example.com"}
    },
    "url" => "http://example.com/?user[context]=regular"
  })

  test "accessing form_params keeps url_params with the same keys" do
    assert_equal "regular", reflex_data.params["user"]["context"]
    assert_equal "test@example.com", reflex_data.params["user"]["email"]
  end

  test "form_params take precedence over url_params with the same keys" do
    data = StimulusReflex::ReflexData.new({
      "form_data" => "user[email]=new%40example.com&items[1][tags][]=&items[1][tags][]=a&items[1][tags][]=b",
      "url" => "http://example.com/?user[email]=old%40example.com&items[1][tags][]="
    })

    assert_equal "new@example.com", data.params["user"]["email"]
    assert_equal ["", "a", "b"], data.params["items"]["1"]["tags"]
  end
end
