# frozen_string_literal: true

module StimulusReflex
  module ConcernEnhancer
    extend ActiveSupport::Concern

    class_methods do
      def method_missing(name, *args)
        case ancestors
        when ->(a) { !(a & [StimulusReflex::Reflex]).empty? }
          if ((defined?(ActiveRecord) ? ActiveRecord::Base.public_methods : []) + ActionController::Base.public_methods).include? name
            nil
          else
            super
          end
        when ->(a) { !(a & (defined?(ActiveRecord) ? [ActiveRecord::Base, ActionController::Base] : [ActionController::Base])).empty? }
          if StimulusReflex::Reflex.public_methods.include? name
            nil
          else
            super
          end
        else
          super
        end
      end

      def respond_to_missing?(name, include_all = false)
        case ancestors
        when ->(a) { !(a & [StimulusReflex::Reflex]).empty? }
          ((defined?(ActiveRecord) ? ActiveRecord::Base.public_methods : []) + ActionController::Base.public_methods).include?(name) || super
        when ->(a) { !(a & (defined?(ActiveRecord) ? [ActiveRecord::Base, ActionController::Base] : [ActionController::Base])).empty? }
          StimulusReflex::Reflex.public_methods.include?(name) || super
        else
          super
        end
      end
    end
  end
end
