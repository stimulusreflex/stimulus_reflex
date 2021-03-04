module StimulusReflex
  module Concern
    extend ActiveSupport::Concern

    included do
      module_eval do
        extend ActiveSupport::Concern
      end
    end

    class_methods do
      def method_missing(name, *args)
        case ancestors
        when ->(a) { !(a & [StimulusReflex::Reflex]).empty? }
          if (ActiveRecord::Base.public_methods + ActionController::Base.public_methods).include? name
            nil
          else
            super
          end
        when ->(a) { !(a & [ActiveRecord::Base, ActionController::Base]).empty? }
          if StimulusReflex::Reflex.public_methods.include? name
            nil
          else
            super
          end
        end
      end
    end
  end
end
