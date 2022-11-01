def gemfile_hash
  Digest::MD5.hexdigest(File.read(Rails.root.join("Gemfile")))
end

hash = gemfile_hash

# run bundle only when gems are waiting to be added or removed
add_gem_list = Rails.root.join("tmp/stimulus_reflex_installer/add_gem_list")
remove_gem_list = Rails.root.join("tmp/stimulus_reflex_installer/remove_gem_list")

gemfile = Rails.root.join("Gemfile")
lines = File.readlines(gemfile)

add = add_gem_list.exist? ? File.readlines(add_gem_list).map(&:chomp) : []
remove = remove_gem_list.exist? ? File.readlines(remove_gem_list).map(&:chomp) : []

if add.present? || remove.present?

  remove.each do |name|
    index = lines.index { |line| line =~ /gem ['"]#{name}['"]/ }
    if index
      if /^[^#]*gem ['"]#{name}['"]/.match?(lines[index])
        lines[index] = "# #{lines[index]}"
      end
      say "✅ #{name} gem has been disabled"
    end
  end

  add.each do |package|
    matches = package.match(/(.+)@(.+)/)
    name, version = matches[1], matches[2]

    index = lines.index { |line| line =~ /gem ['"]#{name}['"]/ }
    if index
      if !lines[index].match(/^[^#]*gem ['"]#{name}['"].*#{version}['"]/)
        lines[index] = "\ngem \"#{name}\", \"#{version}\"\n"
      end
    else
      lines << "\ngem \"#{name}\", \"#{version}\"\n"
    end
    say "✅ #{name} gem has been installed"
  end

  File.write(gemfile, lines.join)

  system("bash -c 'bundle'") if hash != gemfile_hash
end

create_file "tmp/stimulus_reflex_installer/bundle", verbose: false
