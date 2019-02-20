require "uri"
require "rack"
require "nokogiri"
require "active_support/all"
require "action_dispatch"
require "cable_ready"

class StimulusReflex::Channel < ActionCable::Channel::Base
  include CableReady::Broadcaster

  def stream_name
    ids = connection.identifiers.map { |identifier|
      send(identifier).try(:id)
    }
    "#{channel_name}#{ids.join ":"}"
  end

  def subscribed
    stream_from stream_name
  end

  def receive(data)
    ActiveSupport::Notifications.instrument "receive.stimulus_reflex", data do
      url = data["url"].to_s
      target = data["target"].to_s
      reflex_name, method_name = target.split("#")
      reflex_name = reflex_name.classify
      arguments = data["args"] || []

      begin
        reflex = reflex_name.constantize.new(self, url: url)
        delegate_call_to_reflex reflex, method_name, arguments
      rescue => invoke_error
        logger.error "StimulusReflex::Channel Failed to invoke #{target}! #{url} #{invoke_error}"
      end

      begin
        render_page_and_broadcast_morph url, reflex
      rescue => render_error
        logger.error "StimulusReflex::Channel Failed to rerender #{url} #{render_error}"
      end
    end
  end

  private

  def delegate_call_to_reflex(reflex, method_name, arguments = [])
    instrument_payload = {reflex: reflex.class.name, method_name: method_name, arguments: arguments.inspect}
    ActiveSupport::Notifications.instrument "delegate_call.stimulus_reflex", instrument_payload do
      if reflex.method(method_name).arity > 0
        reflex.send method_name, *arguments
      else
        reflex.send method_name
      end
    end
  end

  def render_page_and_broadcast_morph(url, reflex)
    html = render_page(url, reflex)
    broadcast_morph url, html if html.present?
  end

  def render_page(url, reflex)
    html = nil
    ActiveSupport::Notifications.instrument "render_page.stimulus_reflex", url: url do
      uri = URI.parse(url)
      url_params = Rails.application.routes.recognize_path(url)
      controller_class = "#{url_params[:controller]}_controller".classify.constantize
      controller = controller_class.new
      controller.instance_variable_set :"@stimulus_reflex", true
      reflex.instance_variables.each do |name|
        controller.instance_variable_set name, reflex.instance_variable_get(name)
      end

      query_hash = Rack::Utils.parse_nested_query(uri.query)
      env = {
        "action_dispatch.request.path_parameters" => url_params,
        "action_dispatch.request.query_parameters" => query_hash,
        "rack.request.query_hash" => query_hash,
        "rack.request.query_string" => uri.query,
        Rack::PATH_INFO => "",
        Rack::QUERY_STRING => uri.query,
        Rack::REQUEST_PATH => uri.path,
        Rack::SCRIPT_NAME => "",
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
