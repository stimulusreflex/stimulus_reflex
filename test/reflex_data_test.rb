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
end
