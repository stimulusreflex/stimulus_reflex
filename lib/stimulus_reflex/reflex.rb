# frozen_string_literal: true

class StimulusReflex::Reflex
  attr_reader :channel, :url, :element

  delegate :connection, to: :channel
  delegate :session, to: :request

  def initialize(channel, url: nil, element: nil)
    @channel = channel
    @url = url
    @element = element
  end

  def request
    @request ||= ActionDispatch::Request.new(connection.env)
  end
end
