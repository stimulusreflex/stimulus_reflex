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

  def wait_for_it(target)
    Thread.new do
      @channel.receive({
        "target" => "#{self.class}##{target}",
        "args" => yield, 
        "url" => @url
      })
    end if block_given?
  end

end
