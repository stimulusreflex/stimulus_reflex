options_path = Rails.root.join("tmp/stimulus_reflex_installer/options")
options = YAML.safe_load(File.read(options_path))
initializer_working_path = Rails.root.join("tmp/stimulus_reflex_installer/working/action_cable.rb")
initializer = File.read(initializer_working_path)

proceed = true
if initializer.exclude? "PermessageDeflate.configure"
  proceed = if options.key? "compression"
    options["compression"]
  else
    !no?("Configure Action Cable to compress your WebSocket traffic with gzip? (Y/n)")
  end
end

if proceed
  add_gem_list = Rails.root.join("tmp/stimulus_reflex_installer/add_gem_list")
  gemfile = Rails.root.join("Gemfile")
  if !File.read(gemfile).match?(/gem ['"]permessage_deflate['"]/)
    FileUtils.touch(add_gem_list)
    append_file(add_gem_list, "permessage_deflate@>= 0.1\n", verbose: false)
    say "✅ Enqueued permessage_deflate to be added to the Gemfile"
  end



  # add permessage_deflate config to Action Cable initializer
  if initializer.exclude? "PermessageDeflate.configure"
    append_file(initializer_working_path, verbose: false) do
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
  end
  say "✅ Action Cable initializer patched to deflate WS traffic"
end

create_file "tmp/stimulus_reflex_installer/compression", verbose: false
