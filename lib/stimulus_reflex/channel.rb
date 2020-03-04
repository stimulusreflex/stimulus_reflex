# frozen_string_literal: true

class StimulusReflex::Channel < ActionCable::Channel::Base
  include CableReady::Broadcaster

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
    url = data["url"].to_s
    selectors = (data["selectors"] || []).select(&:present?)
    selectors = data["selectors"] = ["body"] if selectors.blank?
    target = data["target"].to_s
    reflex_name, method_name = target.split("#")
    reflex_name = reflex_name.classify
    arguments = data["args"] || []
    element = StimulusReflex::Element.new(data["attrs"])

    begin
      reflex_class = reflex_name.constantize
      raise ArgumentError.new("#{reflex_name} is not a StimulusReflex::Reflex") unless is_reflex?(reflex_class)
      reflex = reflex_class.new(self, url: url, element: element, selectors: selectors)
      delegate_call_to_reflex reflex, method_name, arguments
    rescue => invoke_error
      message = exception_message_with_backtrace(invoke_error)
      return broadcast_error("StimulusReflex::Channel Failed to invoke #{target}! #{url} #{message}", data)
    end

    begin
      render_page_and_broadcast_morph url, reflex, selectors, data
    rescue => render_error
      message = exception_message_with_backtrace(render_error)
      broadcast_error "StimulusReflex::Channel Failed to re-render #{url} #{message}", data
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

  def render_page_and_broadcast_morph(url, reflex, selectors, data = {})
    html = render_page(url, reflex)
    broadcast_morphs selectors, data, html if html.present?
  end

  def commit_session(request, response)
    store = request.session.instance_variable_get("@by")
    store.commit_session request, response
  rescue => e
    message = "Failed to commit session! #{exception_message_with_backtrace(e)}"
    logger.error "\e[31m#{message}\e[0m"
  end

  def render_page(url, reflex)
    uri = URI.parse(url)
    path = ActionDispatch::Journey::Router::Utils.normalize_path(uri.path)
    query_hash = Rack::Utils.parse_nested_query(uri.query)
    request = ActionDispatch::Request.new(
      connection.env.merge(
        Rack::MockRequest.env_for(uri.to_s).merge(
          "rack.request.query_hash" => query_hash,
          "rack.request.query_string" => uri.query,
          "ORIGINAL_SCRIPT_NAME" => "",
          "ORIGINAL_FULLPATH" => path,
          Rack::SCRIPT_NAME => "",
          Rack::PATH_INFO => path,
          Rack::REQUEST_PATH => path,
          Rack::QUERY_STRING => uri.query
        )
      )
    )
    url_params = Rails.application.routes.recognize_path_with_request(request, request.path, request.env[:extras] || {})
    controller = request.controller_class.new
    controller.instance_variable_set :"@stimulus_reflex", true
    reflex.instance_variables.each do |name|
      controller.instance_variable_set name, reflex.instance_variable_get(name)
    end

    controller.request = request
    controller.response = ActionDispatch::Response.new
    controller.process url_params[:action]
    commit_session request, controller.response
    controller.response.body
  end

  def broadcast_morphs(selectors, data, html)
    document = Nokogiri::HTML(html)
    selectors = selectors.select { |s| document.css(s).present? }
    selectors.each do |selector|
      cable_ready[stream_name].morph(
        selector: selector,
        html: document.css(selector).inner_html,
        children_only: true,
        permanent_attribute_name: data["permanent_attribute_name"],
        stimulus_reflex: data.merge(last: selector == selectors.last)
      )
    end
    cable_ready.broadcast
  end

  def broadcast_error(message, data = {})
    logger.error "\e[31m#{message}\e[0m"
    cable_ready[stream_name].dispatch_event(
      name: "stimulus-reflex:500",
      detail: {stimulus_reflex: data.merge(error: message)}
    )
    cable_ready.broadcast
  end

  def exception_message_with_backtrace(exception)
    "#{exception} #{exception.backtrace.first}"
  end
end
