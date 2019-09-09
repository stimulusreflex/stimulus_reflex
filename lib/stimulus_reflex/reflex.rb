# frozen_string_literal: true

class StimulusReflex::Reflex
  attr_reader :channel, :url, :action_variables

  delegate :connection, to: :channel
  delegate :session, to: :request

  def initialize(channel, url: nil)
    @channel = channel
    @url = url
    @action_variables = access_controller_instance_variables
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

  protected

  def access_controller_instance_variables
    uri = URI.parse(@url)
    url_params = Rails.application.routes.recognize_path(@url)
    controller_class = "#{url_params[:controller]}_controller".classify.constantize
    controller = controller_class.new

    controller.instance_variable_set :"@stimulus_reflex_no_render", true

    query_hash = Rack::Utils.parse_nested_query(uri.query)
    env = {
      "action_dispatch.request.path_parameters" => url_params,
      "action_dispatch.request.query_parameters" => query_hash,
      "rack.request.query_hash" => query_hash,
      "rack.request.query_string" => uri.query,
      "ORIGINAL_SCRIPT_NAME" => "",
      "ORIGINAL_FULLPATH" => uri.path,
      Rack::SCRIPT_NAME => "",
      Rack::PATH_INFO => uri.path,
      Rack::REQUEST_PATH => uri.path,
      Rack::QUERY_STRING => uri.query,
    }

    request = ActionDispatch::Request.new(connection.env.merge(env))
    controller.request = request
    controller.response = ActionDispatch::Response.new
    controller.process url_params[:action]

    controller.instance_variables.inject(HashWithIndifferentAccess.new) do |result, name|
      result[name[1..-1].to_sym] = controller.instance_variable_get(name)
      result
    end
  end

end
