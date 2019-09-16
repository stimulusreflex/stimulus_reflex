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
    controller_name = reflex_name[0..-7].downcase
    reflex_name = reflex_name.classify
    arguments = data["args"] || []
    element = StimulusReflex::Element.new(data["attrs"])

    begin
      reflex_class = reflex_name.constantize
      raise ArgumentError.new("#{reflex_name} is not a StimulusReflex::Reflex") unless is_reflex?(reflex_class)
      reflex = reflex_class.new(self, url: url, element: element)
      delegate_call_to_reflex reflex, method_name, arguments
    rescue => invoke_error
      logger.error "\e[31mStimulusReflex::Channel Failed to invoke #{target}! #{url} #{invoke_error}\e[0m"
    end

    begin
      render_page_and_broadcast_morph url, reflex, controller_name, method_name
    rescue => render_error
      logger.error "\e[31mStimulusReflex::Channel Failed to rerender #{url} #{render_error}\e[0m"
    end
  end

  private

  def is_reflex?(reflex_class)
    reflex_class.ancestors.include? StimulusReflex::Reflex
  end

  def delegate_call_to_reflex(reflex, method_name, arguments = [])
    method = reflex.method(method_name)
    required_params = method.parameters.select { |(kind, _)| kind == :req }
    optional_params = method.parameters.select { |(kind, _)| kind == :opt }

    if arguments.size == 0 && required_params.size == 0
      reflex.public_send method_name
    elsif arguments.size >= required_params.size && arguments.size <= required_params.size + optional_params.size
      reflex.public_send method_name, *arguments
    else
      raise ArgumentError.new("wrong number of arguments (given #{arguments.inspect}, expected #{required_params.inspect}, optional #{optional_params.inspect})")
    end
  end

  def render_page_and_broadcast_morph(url, reflex, controller_name, method_name)
    html = render_page(url, reflex)
    broadcast_morph url, reflex, controller_name, method_name, html if html.present?
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

  def broadcast_morph(url, reflex, controller_name, method_name, html)
    html = extract_body_html(html)
    cable_ready[stream_name].morph({
      selector: "body",
      html: html,
      children_only: true,
      callback: reflex.callback,
      redirect: reflex.redirect,
      controller: controller_name,
      method: method_name,
    })
    cable_ready.broadcast
  end

  def extract_body_html(html)
    doc = Nokogiri::HTML(html)
    doc.css("body").to_s
  end
end
