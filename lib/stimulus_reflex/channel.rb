# frozen_string_literal: true

class StimulusReflex::Channel < ActionCable::Channel::Base
  include CableReady::Broadcaster

  def stream_name
    ids = connection.identifiers.map { |identifier| send(identifier).try(:id) }
    [
      params[:channel],
      params[:room],
      ids.select(&:present?).join(";"),
    ].select(&:present?).join(":")
  end

  def subscribed
    stream_from stream_name
  end

  def receive(data)
    url = data["url"].to_s
    target = data["target"].to_s
    reflex_name, method_name = target.split("#")
    reflex_name = reflex_name.classify
    arguments = data["args"] || []
    options = StimulusReflex::DomElement.new(data["attrs"])

    begin
      reflex = reflex_name.constantize.new(self, url: url)
      delegate_call_to_reflex reflex, method_name, arguments, options
    rescue => invoke_error
      logger.error "\e[31mStimulusReflex::Channel Failed to invoke #{target}! #{url} #{invoke_error}\e[0m"
    end

    begin
      render_page_and_broadcast_morph url, reflex
    rescue => render_error
      logger.error "\e[31mStimulusReflex::Channel Failed to rerender #{url} #{render_error}\e[0m"
    end
  end

  private

  def delegate_call_to_reflex(reflex, method_name, arguments = [], options = {})
    method = reflex.method(method_name)
    required_params = method.parameters.select { |(kind, _)| kind == :req }
    optional_params = method.parameters.select { |(kind, _)| kind == :opt }
    accepts_options_kwarg = method.parameters.select { |(kind, name)| name == :options && kind.to_s.start_with?("key") }.size > 0

    if arguments.size == 0 && required_params.size == 0
      if accepts_options_kwarg
        reflex.public_send method_name, {options: options}
      else
        reflex.public_send method_name
      end
    elsif arguments.size >= required_params.size && arguments.size <= required_params.size + optional_params.size
      if accepts_options_kwarg
        reflex.public_send method_name, *arguments, {options: options}
      else
        reflex.public_send method_name, *arguments
      end
    else
      raise ArgumentError.new("wrong number of arguments (given #{arguments.inspect}, expected #{required_params.inspect}, optional #{optional_params.inspect})")
    end
  end

  def render_page_and_broadcast_morph(url, reflex)
    html = render_page(url, reflex)
    broadcast_morph url, html if html.present?
  end

  def render_page(url, reflex)
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
    controller.response.body
  end

  def broadcast_morph(url, html)
    html = extract_body_html(html)
    cable_ready[stream_name].morph selector: "body", html: html, children_only: true
    cable_ready.broadcast
  end

  def extract_body_html(html)
    doc = Nokogiri::HTML(html)
    doc.css("body").to_s
  end
end
