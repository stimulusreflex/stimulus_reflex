# frozen_string_literal: true

class StimulusReflex::TargetsCollection
  attr_reader :target_elements, :cable_ready

  delegate :broadcast, to: :cable_ready

  def initialize(elements = [], cable_ready: nil)
    @target_elements = elements
    @cable_ready = cable_ready
  end

  private

  def method_missing(method_name, *arguments, &block)
    if cable_ready.respond_to?(method_name)
      args = arguments.first.to_h
      selector = target_elements.first.selector

      cable_ready.send(method_name.to_sym, args.merge(selector: selector, select_all: true))

      self
    else
      target_elements.send(method_name)
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    cable_ready.respond_to?(method_name) || target_elements.respond_to?(method_name)
  end
end
