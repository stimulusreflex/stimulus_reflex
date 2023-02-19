# frozen_string_literal: true

module StimulusReflex
  module Broadcasters
    class Update
      include CableReady::Identifiable

      def initialize(key, value, reflex)
        @key = key
        @value = value
        @reflex = reflex
      end

      def selector
        @selector ||= identifiable?(@key) ? dom_id(@key) : @key.to_s
      end

      def html
        return @value unless defined?(ActiveRecord)
        html = @reflex.render(@key) if @key.is_a?(ActiveRecord::Base) && @value.nil?
        html = @reflex.render_collection(@key) if @key.is_a?(ActiveRecord::Relation) && @value.nil?
        html || @value
      end
    end
  end
end
