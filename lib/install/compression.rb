# frozen_string_literal: true

require "stimulus_reflex/installer"

initializer = action_cable_initializer_working_path.read

if gemfile.match?(/gem ['"]permessage_deflate['"]/)
  say "⏩ permessage_deflate already present in Gemfile. Skipping."
else
  add_gem "permessage_deflate@>= 0.1"
end

# add permessage_deflate config to Action Cable initializer
if initializer.exclude? "PermessageDeflate.configure"
  create_or_append(action_cable_initializer_working_path, verbose: false) do
    <<~RUBY
      module ActionCable
        module Connection
          class ClientSocket
            alias_method :old_initialize, :initialize
            def initialize(env, event_target, event_loop, protocols)
              old_initialize(env, event_target, event_loop, protocols)
              @driver.add_extension(
                PermessageDeflate.configure(
                  level: Zlib::BEST_COMPRESSION,
                  max_window_bits: 13
                )
              )
            end
          end
        end
      end
    RUBY
  end

  say "✅ Action Cable initializer patched to deflate WS traffic"
else
  say "⏩ Action Cable initializer is already patched to deflate WS traffic. Skipping."
end

complete_step :compression
