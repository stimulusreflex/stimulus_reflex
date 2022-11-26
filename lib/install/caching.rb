caching = Rails.root.join("tmp/caching-dev.txt")

# Enable caching in development
if !caching.exist?
  FileUtils.touch(caching)
  say "✅ Caching enabled in the development environment"
end

create_file "tmp/stimulus_reflex_installer/caching", verbose: false
