require "uri"
require "rack"
require "nokogiri"
require "active_support/all"
require "action_dispatch"
require "cable_ready"

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
    ActiveSupport::Notifications.instrument "receive.stimulus_reflex", data do
      start = Time.current
      url = data["url"].to_s
      target = data["target"].to_s
      stimulus_controller_name, method_name = target.split("#")
      stimulus_controller_name = "#{stimulus_controller_name.classify}StimulusController"
      arguments = data["args"] || []

      begin
        stimulus_controller = stimulus_controller_name.constantize.new(self)
        delegate_call_to_stimulus_controller stimulus_controller, method_name, arguments
        render_page_and_broadcast_morph url
      rescue StandardError => invoke_error
        logger.error "StimulusReflex::Channel Failed to invoke #{target}! #{url} #{invoke_error}"
      end
    end
  end

  private

  def delegate_call_to_stimulus_controller(stimulus_controller, method_name, arguments = [])
    instrument_payload = {stimulus_controller: stimulus_controller.class.name, method_name: method_name, arguments: arguments.inspect}
    ActiveSupport::Notifications.instrument "delegate_call.stimulus_reflex", instrument_payload do
      if stimulus_controller.method(method_name).arity > 0
        stimulus_controller.send method_name, *arguments
      else
        stimulus_controller.send method_name
      end
    end
  end

  def render_page_and_broadcast_morph(url)
    html = render_page(url)
    broadcast_morph url, html if html.present?
  end

  def render_page(url)
    html = nil
    ActiveSupport::Notifications.instrument "render_page.stimulus_reflex", url: url do
      uri = URI.parse(url)
      url_params = Rails.application.routes.recognize_path(url)
      controller_class = "#{url_params[:controller]}_controller".classify.constantize
      controller = controller_class.new
      controller.instance_variable_set :"@stimulus_reflex", true

      env = {
        Rack::SCRIPT_NAME => uri.path,
        Rack::QUERY_STRING => uri.query,
        Rack::PATH_INFO => "",
      }
      request = ActionDispatch::Request.new(connection.env.merge(env))
      controller.request = request
      controller.response = ActionDispatch::Response.new
      controller.process url_params[:action]
      html = controller.response.body
    end
    html
  end

  def broadcast_morph(url, html)
    ActiveSupport::Notifications.instrument "broadcast.stimulus_reflex", url: url, cable_ready: :morph do
      html = extract_body_html(html)
      cable_ready[stream_name].morph selector: "body", html: html, children_only: true
      cable_ready.broadcast
    end
  end

  def extract_body_html(html)
    doc = Nokogiri::HTML(html)
    doc.css("body").to_s
  end
end
