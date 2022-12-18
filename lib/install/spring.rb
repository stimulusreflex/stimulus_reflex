require "stimulus_reflex/installer"

spring_pattern = /^[^#]*gem ["']spring["']/

proceed = true
lines = gemfile_path.readlines
if lines.index { |line| line =~ spring_pattern }
  proceed = if options.key? "spring"
    options["spring"]
  else
    !no?("Would you like to disable the spring gem? \nIt's been removed from Rails 7, and is the frequent culprit behind countless mystery bugs. (Y/n)")
  end
end

if proceed
  spring_watcher_pattern = /^[^#]*gem ["']spring-watcher-listen["']/
  bin_rails_pattern = /^[^#]*load File.expand_path\("spring", __dir__\)/

  if (index = lines.index { |line| line =~ spring_pattern })
    remove_gem :spring

    bin_spring = Rails.root.join("bin/spring")
    if bin_spring.exist?
      run "bin/spring binstub --remove --all"
      say "✅ Removed spring binstubs"
    end

    bin_rails = Rails.root.join("bin/rails")
    bin_rails_content = bin_rails.readlines
    if (index = bin_rails_content.index { |line| line =~ bin_rails_pattern })
      backup(bin_rails) do
        bin_rails_content[index] = "# #{bin_rails_content[index]}"
        bin_rails.write bin_rails_content.join
      end
      say "✅ Removed spring from bin/rails"
    end
    create_file "tmp/stimulus_reflex_installer/kill_spring", verbose: false
  else
    say "✅ spring has been successfully 86'd"
  end

  if lines.index { |line| line =~ spring_watcher_pattern }
    remove_gem "spring-watcher-listen"
  end
end

complete_step :spring
