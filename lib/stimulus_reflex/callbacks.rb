# frozen_string_literal: true

require "active_support/concern"

module StimulusReflex
  module Callbacks
    extend ActiveSupport::Concern

    included do
      include ActiveSupport::Callbacks
      define_callbacks :process, skip_after_callbacks_if_terminated: true, terminator: ->(target, result_lambda) do
        halted = true
        forbidden = true
        catch(:abort) do
          catch(:forbidden) do
            result_lambda.call
            forbidden = false
          end
          halted = false
        end
        forbidden = false if halted == true
        target.instance_variable_set(:@halted, halted)
        target.instance_variable_set(:@forbidden, forbidden)
        halted || forbidden
      end
    end

    class_methods do
      def before_reflex(*args, &block)
        add_callback(:before, *args, &block)
      end

      def after_reflex(*args, &block)
        add_callback(:after, *args, &block)
      end

      def around_reflex(*args, &block)
        add_callback(:around, *args, &block)
      end

      def prepend_before_reflex(*args, &block)
        prepend_callback(:before, *args, &block)
      end

      def prepend_after_reflex(*args, &block)
        prepend_callback(:after, *args, &block)
      end

      def prepend_around_reflex(*args, &block)
        prepend_callback(:around, *args, &block)
      end

      def skip_before_reflex(*args, &block)
        omit_callback(:before, *args, &block)
      end

      def skip_after_reflex(*args, &block)
        omit_callback(:after, *args, &block)
      end

      def skip_around_reflex(*args, &block)
        omit_callback(:around, *args, &block)
      end

      alias_method :append_before_reflex, :before_reflex
      alias_method :append_around_reflex, :around_reflex
      alias_method :append_after_reflex, :after_reflex

      private

      def add_callback(kind, *args, &block)
        insert_callbacks(args, block) do |name, options|
          set_callback(:process, kind, name, options)
        end
      end

      def prepend_callback(kind, *args, &block)
        insert_callbacks(args, block) do |name, options|
          set_callback(:process, kind, name, options.merge(prepend: true))
        end
      end

      def omit_callback(kind, *args, &block)
        insert_callbacks(args) do |name, options|
          skip_callback(:process, kind, name, options)
        end
      end

      def insert_callbacks(callbacks, block = nil)
        options = callbacks.extract_options!
        normalize_callback_options!(options)

        callbacks.push(block) if block

        callbacks.each do |callback|
          yield callback, options
        end
      end

      def normalize_callback_options!(options)
        normalize_callback_option! options, :only, :if
        normalize_callback_option! options, :except, :unless
      end

      def normalize_callback_option!(options, from, to)
        if (from = options.delete(from))
          from_set = Array(from).map(&:to_s).to_set
          from = proc { |reflex| from_set.include? reflex.method_name.to_s }
          options[to] = Array(options[to]).unshift(from)
        end
      end
    end
  end
end
