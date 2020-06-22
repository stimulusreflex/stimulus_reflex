# frozen_string_literal: true

module ActionCable
  module Channel
    class Base
      def subscribed
        puts 'INSIDE GEM'
      end
    end
  end
end
