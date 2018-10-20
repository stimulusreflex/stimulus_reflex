require "uri"
require "rack"
require "nokogiri"
require "active_support/all"
require "action_dispatch"
require "cable_ready"

#class StimulusReflex::Channel < ApplicationCable::Channel
class StimulusReflex::Channel < ActionCable::Channel::Base
  include CableReady::Broadcaster

  def stream_name
    ids = connection.identifiers.map do |identifier|
      send(identifier).try(:id)
    end
    "#{channel_name}#{ids.join ":"}"
  end

  def subscribed
    stream_from stream_name
  end

  def receive(data)
    logger.debug "StimulusReflex::Channel#receive #{data.inspect}"
    start = Time.current
    url = data["url"].to_s
    target = data["target"].to_s
    stimulus_controller_name, stimulus_method_name = target.split("#")
    stimulus_controller_name = "#{stimulus_controller_name.classify}StimulusController"
    stimulus_controller = nil
    arguments = data["args"]

    begin
      ActiveSupport::Notifications.instrument "delegate_call.stimulus_reflex", url: url, target: target, arguments: arguments do
        stimulus_controller = stimulus_controller_name.constantize.new(self)
        if arguments.present?
          stimulus_controller.send stimulus_method_name, *arguments
        else
          stimulus_controller.send stimulus_method_name
        end
      end

      begin
        html = render_page(url, stimulus_controller)
        broadcast_morph extract_body_html(html)
      rescue StandardError => render_error
        logger.error "StimulusReflex::Channel: #{url} Failed to rerender #{params} after invoking #{target}! #{render_error} #{render_error.backtrace}"
      end
    rescue StandardError => invoke_error
      logger.error "StimulusReflex::Channel: #{url} Failed to invoke #{target}! #{invoke_error}"
    end
  end

  private

  def render_page(url, stimulus_controller)
    params = Rails.application.routes.recognize_path(url)
    controller_class = "#{params[:controller]}_controller".classify.constantize
    controller = controller_class.new
    controller.instance_variable_set :"@stimulus_reflex", true
    stimulus_controller.instance_variables.each do |instance_variable_name|
      controller.instance_variable_set instance_variable_name, stimulus_controller.instance_variable_get(instance_variable_name)
    end

    uri = URI.parse(url)
    env = {
      Rack::SCRIPT_NAME => uri.path,
      Rack::QUERY_STRING => uri.query,
      Rack::PATH_INFO => ""
    }
    request = ActionDispatch::Request.new(connection.env.merge(env))
    controller.request = request
    controller.response = ActionDispatch::Response.new

    ActiveSupport::Notifications.instrument "process_controller_action.stimulus_reflex", url: url do
      controller.process params[:action]
    end
    controller.response.body
  end

  def extract_body_html(html)
    doc = Nokogiri::HTML(html)
    doc.css("body").to_s
  end

  def broadcast_morph(html)
    cable_ready[stream_name].morph selector: "body", html: html, children_only: true
    cable_ready.broadcast
  end
end
