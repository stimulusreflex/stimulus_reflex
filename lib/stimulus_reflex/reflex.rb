# frozen_string_literal: true

class StimulusReflex::Reflex
  attr_reader :channel, :url, :element, :selectors

  delegate :connection, to: :channel
  delegate :session, to: :request

  def initialize(channel, url: nil, element: nil, selectors: nil)
    @channel = channel
    @url = url
    @element = element
    @selectors = selectors
  end

  def request
    @request ||= ActionDispatch::Request.new(connection.env)
  end
end
