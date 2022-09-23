# verify app/reflexes exists and create if necessary
reflexes_path = Rails.root.join("app/reflexes")
if reflexes_path.exist?
  say "✅ app/reflexes directory is present"
else
  empty_directory reflexes_path
end

templates_path = File.expand_path("../generators/stimulus_reflex/templates/app/reflexes", File.join(File.dirname(__FILE__)))
application_reflex_path = Rails.root.join("app/reflexes/application_reflex.rb")
application_reflex_src = templates_path + "/application_reflex.rb.tt"
if application_reflex_path.exist?
  say "✅ app/reflexes/application_reflex.rb is present"
else
  copy_file application_reflex_src, application_reflex_path
end

create_file "tmp/stimulus_reflex_installer/reflexes", verbose: false
