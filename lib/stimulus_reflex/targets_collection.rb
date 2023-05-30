# frozen_string_literal: true

class StimulusReflex::TargetsCollection
  attr_reader :target_name, :target_elements, :cable_ready

  delegate *Array.instance_methods.excluding(:__send__, :object_id), to: :target_elements
  delegate :broadcast, to: :cable_ready

  def initialize(elements = [], cable_ready: nil)
    @target_elements = elements
    @target_name = elements.first.dataset.reflex_target
    @cable_ready = cable_ready
  end

  private

  def method_missing(method_name, *arguments, &block)
    if cable_ready.respond_to?(method_name)
      args = arguments.first.to_h
      selector = "[data-reflex-target='#{target_name}']"

      cable_ready.send(method_name.to_sym, args.merge(selector: selector, select_all: true))

      self
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    cable_ready.respond_to?(method_name)
  end
end
