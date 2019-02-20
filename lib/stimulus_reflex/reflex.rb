class StimulusReflex::Reflex
  attr_reader :channel, :url

  delegate :connection, to: :channel
  delegate :session, to: :request

  def initialize(channel, url: nil)
    @channel = channel
    @url = url
  end

  def request
    @request ||= ActionDispatch::Request.new(connection.env)
  end
end
