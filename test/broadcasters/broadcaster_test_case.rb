# frozen_string_literal: true

require_relative "../test_helper"

class StimulusReflex::BroadcasterTestCase < ActionCable::Channel::TestCase
  tests StimulusReflex::Channel

  setup do
    stub_connection(session_id: SecureRandom.uuid)
    def connection.env
      @env ||= {}
    end
    @reflex = StimulusReflex::Reflex.new(subscribe, url: "https://test.stimulusreflex.com")
  end
end
