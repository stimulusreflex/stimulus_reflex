module StimulusReflex
  class ApplicationController < ActionController::Base
    skip_forgery_protection

    def receive
      data = params.permit!.to_h
      adapter = StimulusReflex::Transport::MessageBusAdapter.new(request, headers['X-StimulusReflex-Identifier'])
      StimulusReflex::Service::ReflexInvoker.new(data, adapter).call
    end
  end
end
