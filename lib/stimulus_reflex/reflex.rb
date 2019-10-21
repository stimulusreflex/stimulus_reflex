# frozen_string_literal: true

class StimulusReflex::Reflex
  attr_reader :channel, :url, :element, :selectors, :abort

  delegate :connection, to: :channel
  delegate :session, to: :request

  def initialize(channel, url: nil, element: nil, selectors: [])
    @channel = channel
    @url = url
    @element = element
    @selectors = selectors
    @abort = false
  end

  def request
    @request ||= ActionDispatch::Request.new(connection.env)
  end

  def cancel_reflex!
    @abort = true
  end
end
