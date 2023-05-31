# frozen_string_literal: true

# A null object that responds to methods like any? and many? with: false, and methods like
# count and length with: 0, and recursively cancels any chained operations invoked on itself.

class StimulusReflex::MissingTarget
  attr_reader :target_elements

  delegate *Array.instance_methods.excluding(:__send__, :object_id), to: :target_elements

  def initialize
    @target_elements = []
  end

  # Silently cancels any/all methods that might have been chained onto a missing target and
  # avoids the associated exceptions that would have arisen from invoking the chained method(s)
  # on NilClass (for a method chain of N length), allowing code execution to continue. Eg;
  #
  # def targets_example
  #   nonexistent_target.inner_html(...).add_css_class(...)   # All operations ignored
  #   existing_target.add_css_class(...)                      # Still gets executed
  # end
  #
  def method_missing(_method_name, *_arguments, &_block)
    self
  end

  def respond_to_missing?(method_name, include_private = false)
    StimulusReflex::CableReadyChannels.public_instance_methods.include? method_name
  end
end
