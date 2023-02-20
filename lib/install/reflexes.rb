# frozen_string_literal: true

require "stimulus_reflex/installer"

reflexes_path = Rails.root.join("app/reflexes")
step_path = "/app/reflexes/"
application_reflex_path = reflexes_path / "application_reflex.rb"
application_reflex_src = fetch(step_path, "application_reflex.rb.tt")

# verify app/reflexes exists and create if necessary
if reflexes_path.exist?
  say "⏩ app/reflexes directory already exists. Skipping."
else
  empty_directory reflexes_path
  say "✅ Created app/reflexes directory"
end

if application_reflex_path.exist?
  say "⏩ app/reflexes/application_reflex.rb is alredy present. Skipping."
else
  copy_file application_reflex_src, application_reflex_path
  say "✅ Created app/reflexes/application_reflex.rb"
end

complete_step :reflexes
