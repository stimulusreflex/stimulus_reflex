# frozen_string_literal: true

module ApplicationCable
  class Channel < ActionCable::Channel::Base
    def initialize(connection, identifier, params = {})
      super
      application_channel = Rails.root.join("app", "channels", "application_cable", "channel.rb")
      require application_channel if File.exist?(application_channel)
    end
  end
end

class StimulusReflex::Channel < ApplicationCable::Channel
  def stream_name
    ids = connection.identifiers.map { |identifier| send(identifier).try(:id) || send(identifier) }
    [
      params[:channel],
      ids.select(&:present?).join(";")
    ].select(&:present?).join(":")
  end

  def subscribed
    super
    stream_from stream_name
  end

  def receive(data)
    url = data["url"].to_s
    selectors = (data["selectors"] || []).select(&:present?)
    selectors = data["selectors"] = ["body"] if selectors.blank?
    target = data["target"].to_s
    reflex_name, method_name = target.split("#")
    reflex_name = reflex_name.camelize
    reflex_name = reflex_name.end_with?("Reflex") ? reflex_name : "#{reflex_name}Reflex"
    arguments = (data["args"] || []).map { |arg| object_with_indifferent_access arg }
    element = StimulusReflex::Element.new(data)
    permanent_attribute_name = data["permanent_attribute_name"]
    params = data["params"] || {}

    begin
      begin
        reflex_class = reflex_name.constantize.tap { |klass| raise ArgumentError.new("#{reflex_name} is not a StimulusReflex::Reflex") unless is_reflex?(klass) }
        reflex = reflex_class.new(self, url: url, element: element, selectors: selectors, method_name: method_name, permanent_attribute_name: permanent_attribute_name, params: params)
        delegate_call_to_reflex reflex, method_name, arguments
      rescue => invoke_error
        message = exception_message_with_backtrace(invoke_error)
        body = "StimulusReflex::Channel Failed to invoke #{target}! #{url} #{message}"
        if reflex
          reflex.rescue_with_handler(invoke_error)
          reflex.broadcast_message subject: "error", body: body, data: data
        else
          logger.error "\e[31m#{body}\e[0m"
        end
        return
      end

      if reflex.halted?
        reflex.broadcast_message subject: "halted", data: data
      else
        begin
          reflex.broadcast(selectors, data)
        rescue => render_error
          reflex.rescue_with_handler(render_error)
          message = exception_message_with_backtrace(render_error)
          reflex.broadcast_message subject: "error", body: "StimulusReflex::Channel Failed to re-render #{url} #{message}", data: data
        end
      end
    ensure
      commit_session reflex if reflex
    end
  end

  private

  def object_with_indifferent_access(object)
    return object.with_indifferent_access if object.respond_to?(:with_indifferent_access)
    object.map! { |obj| object_with_indifferent_access obj } if object.is_a?(Array)
    object
  end

  def is_reflex?(reflex_class)
    reflex_class.ancestors.include? StimulusReflex::Reflex
  end

  def delegate_call_to_reflex(reflex, method_name, arguments = [])
    method = reflex.method(method_name)
    required_params = method.parameters.select { |(kind, _)| kind == :req }
    optional_params = method.parameters.select { |(kind, _)| kind == :opt }

    if arguments.size == 0 && required_params.size == 0
      reflex.process(method_name)
    elsif arguments.size >= required_params.size && arguments.size <= required_params.size + optional_params.size
      reflex.process(method_name, *arguments)
    else
      raise ArgumentError.new("wrong number of arguments (given #{arguments.inspect}, expected #{required_params.inspect}, optional #{optional_params.inspect})")
    end
  end

  def commit_session(reflex)
    store = reflex.request.session.instance_variable_get("@by")
    store.commit_session reflex.request, reflex.controller.response
  rescue => e
    message = "Failed to commit session! #{exception_message_with_backtrace(e)}"
    logger.error "\e[31m#{message}\e[0m"
  end

  def exception_message_with_backtrace(exception)
    "#{exception} #{exception.backtrace.first}"
  end
end
