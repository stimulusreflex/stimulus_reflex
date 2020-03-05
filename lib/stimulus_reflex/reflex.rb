# frozen_string_literal: true

class StimulusReflex::Reflex
  attr_reader :channel, :request, :element, :selectors

  delegate :connection, to: :channel
  delegate :session, :url, to: :request

  def initialize(channel, request: nil, element: nil, selectors: [])
    @channel = channel
    @request = request
    @element = element
    @selectors = selectors
  end

  def cookies
    @cookies ||= ActionDispatch::Cookies::CookieJar.new(request)
  end
end
