# frozen_string_literal: true

require_relative "../test_helper"

class StimulusReflex::BroadcasterTestCase < ActionCable::Channel::TestCase
  tests StimulusReflex::Channel

  def assert_broadcast_on(stream, data, &block)
    serialized_msg = ActiveSupport::JSON.decode(ActiveSupport::JSON.encode(data))

    new_messages = broadcasts(stream)
    if block
      old_messages = new_messages
      clear_messages(stream)

      yield
      new_messages = broadcasts(stream)
      clear_messages(stream)

      (old_messages + new_messages).each { |m| pubsub_adapter.broadcast(stream, m) }
    end

    message = new_messages.find { |msg| ActiveSupport::JSON.decode(msg) == serialized_msg }

    unless message
      puts "\n\nActual: #{ActiveSupport::JSON.decode(new_messages.first)}\n\nExpected: #{data}\n\n"
    end

    assert message, "No messages sent with #{data} to #{stream}"
  end

  setup do
    stub_connection(session_id: SecureRandom.uuid)
    def connection.env
      @env ||= {}
    end

    data = StimulusReflex::ReflexData.new(url: "https://test.stimulusreflex.com", id: "666", version: StimulusReflex::VERSION)
    @reflex = StimulusReflex::Reflex.new(subscribe, data: data)
  end
end
