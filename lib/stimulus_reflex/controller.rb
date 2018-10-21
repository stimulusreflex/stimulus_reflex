class StimulusReflex::Controller
  attr_reader :channel

  delegate :connection, to: :channel
  delegate :session, to: :request

  def initialize(channel)
    @channel = channel
  end

  def request
    @request ||= ActionDispatch::Request.new(connection.env)
  end
end
