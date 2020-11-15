# frozen_string_literal: true

module StimulusReflex
  module Utils
    module Colorize
      COLORS = {
        red: "31",
        green: "32",
        yellow: "33",
        blue: "34",
        magenta: "35",
        cyan: "36",
        white: "37"
      }

      refine String do
        COLORS.each do |name, code|
          define_method(name) { "\e[#{code}m#{self}\e[0m" }
        end
      end
    end
  end
end
