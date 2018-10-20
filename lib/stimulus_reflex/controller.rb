class StimulusReflex::Controller
  attr_reader :channel

  def initialize(channel)
    @channel = channel
  end
end
