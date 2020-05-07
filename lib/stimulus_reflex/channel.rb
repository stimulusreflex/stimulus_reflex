# frozen_string_literal: true

class StimulusReflex::Channel < ActionCable::Channel::Base
  def initialize(connection, identifier, params = {})
    super

    @transport_adapter = StimulusReflex::Transport::CableReadyAdapter.new(self)
  end

  def stream_name
    ids = connection.identifiers.map { |identifier| send(identifier).try(:id) || send(identifier) }
    [
      params[:channel],
      ids.select(&:present?).join(";")
    ].select(&:present?).join(":")
  end

  def subscribed
    stream_from stream_name
  end

  def receive(data)
    StimulusReflex::Service::ReflexInvoker.new(data, @transport_adapter).call
  end
end
