options_path = Rails.root.join("tmp/stimulus_reflex_installer/options")
options = YAML.safe_load(File.read(options_path))

proceed = if options.key? "compression"
  options["compression"]
else
  !no?("Configure Action Cable to compress your WebSocket traffic with gzip? (Y/n)")
end

if proceed
  # ensure permessage_deflate is included in Gemfile
  gemfile = Rails.root.join("Gemfile")
  lines = File.readlines(gemfile)

  index = lines.index { |line| line =~ /gem ['"]permessage_deflate['"]/ }
  if index
    if !lines[index].match(/^[^#]*gem ['"]permessage_deflate['"]/)
      lines[index] = "\ngem \"permessage_deflate\"n"
    end
  else
    lines << "\ngem \"permessage_deflate\"\n"
  end
  say "✅ permessage_deflate gem has been installed"

  File.write(gemfile, lines.join)

  # install permessage_deflate
  system("bash -c 'bundle --quiet'")

  # add permessage_deflate config to Action Cable initializer
  initializer_path = Rails.root.join("config/initializers/action_cable.rb")
  if File.read(initializer_path).exclude? "PermessageDeflate.configure"
    append_file(initializer_path, verbose: false) do
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
