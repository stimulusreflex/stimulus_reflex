require "stimulus_reflex/installer"

reflexes_path = Rails.root.join("app/reflexes")
templates_path = File.expand_path(template_src + "/app/reflexes", File.join(File.dirname(__FILE__)))
application_reflex_path = reflexes_path / "application_reflex.rb"
application_reflex_src = fetch(templates_path + "/application_reflex.rb.tt")

# verify app/reflexes exists and create if necessary
if reflexes_path.exist?
  say "✅ app/reflexes directory is present"
else
  empty_directory reflexes_path
end

if application_reflex_path.exist?
  say "✅ app/reflexes/application_reflex.rb is present"
else
  copy_file application_reflex_src, application_reflex_path
end

complete_step :reflexes
