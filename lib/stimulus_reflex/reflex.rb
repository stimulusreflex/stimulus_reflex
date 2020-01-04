# frozen_string_literal: true

class StimulusReflex::Reflex
  attr_reader :channel, :url, :element, :selectors

  delegate :connection, to: :channel
  delegate :session, to: :request
  delegate :current_user, to: :connection

  def initialize(channel, url: nil, element: nil, selectors: [])
    @channel = channel
    @url = url
    @element = element
    @selectors = selectors
  end

  def request
    @request ||= ActionDispatch::Request.new(connection.env)
  end
end
