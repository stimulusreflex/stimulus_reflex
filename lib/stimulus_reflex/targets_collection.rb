# frozen_string_literal: true

class StimulusReflex::TargetsCollection
  attr_reader :target_name, :target_elements, :cable_ready

  delegate *Array.instance_methods.excluding(:__send__, :object_id), to: :target_elements
  delegate :broadcast, to: :cable_ready

  def initialize(elements = [], target_name: "", target_scope: nil, reflex_controller: nil, cable_ready: nil)
    @target_elements = elements
    @target_name = target_name
    @target_scope = target_scope
    @reflex_controller = reflex_controller
    @cable_ready = cable_ready
  end

  private

  def method_missing(method_name, *arguments, &block)
    if cable_ready.respond_to?(method_name)
      args = arguments.first.to_h
      parent = @target_scope == "controller" ? "[data-controller='#{@reflex_controller}'] " : nil
      selector = "#{parent}[data-reflex-target='#{target_name}']"

      cable_ready.send(method_name.to_sym, args.merge(selector: selector, select_all: true))

      self
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    cable_ready.respond_to?(method_name)
  end
end
