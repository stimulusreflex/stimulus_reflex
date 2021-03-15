require "active_support/concern"

module StimulusReflex
  module Callbacks
    extend ActiveSupport::Concern

    included do
      include ActiveSupport::Callbacks
      define_callbacks :process, skip_after_callbacks_if_terminated: true
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

      def skip_before_reflex(*args, &block)
        omit_callback(:before, *args, &block)
      end

      def skip_after_reflex(*args, &block)
        omit_callback(:after, *args, &block)
      end

      def skip_around_reflex(*args, &block)
        omit_callback(:around, *args, &block)
      end

      private

      def add_callback(kind, *args, &block)
        set_callback(*[:process, kind, args, normalize_callback_options!(args)].flatten, &block)
      end

      def omit_callback(kind, *args, &block)
        skip_callback(*[:process, kind, args, normalize_callback_options!(args)].flatten, &block)
      end

      def normalize_callback_options!(args)
        options = args.extract_options!
        options.assert_valid_keys :if, :unless, :only, :except

        normalize_callback_option! options, :only, :if
        normalize_callback_option! options, :except, :unless
        options
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
