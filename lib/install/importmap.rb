entrypoint = File.read("tmp/stimulus_reflex_installer/entrypoint")
pack_path = Rails.root.join(entrypoint, "application.js")
friendly_pack_path = pack_path.relative_path_from(Rails.root).to_s

if !pack_path.exist?
  say "❌ #{friendly_pack_path} is missing. You need a valid application pack file to proceed.", :red
  create_file "tmp/stimulus_reflex_installer/halt", verbose: false
  return
end

templates_path = File.expand_path("../generators/stimulus_reflex/templates", File.join(File.dirname(__FILE__)))

importmap_src = templates_path + "/config/importmap.rb.tt"
importmap_path = Rails.root.join("config/importmap.rb")

friendly_importmap_path = importmap_path.relative_path_from(Rails.root).to_s
if importmap_path.exist?
  if File.read(importmap_path) == File.read(importmap_src)
    say "✅ #{friendly_importmap_path} is present"
  else
    copy_file(importmap_path, "#{importmap_path}.bak", verbose: false)
    remove_file(importmap_path, verbose: false)
    copy_file(importmap_src, importmap_path, verbose: false)
    append_file("tmp/stimulus_reflex_installer/backups", "#{friendly_importmap_path}\n", verbose: false)
    say "#{friendly_importmap_path} has been created"
    say "❕ original importmap.rb renamed importmap.rb.bak", :green
  end
else
  copy_file(importmap_src, importmap_path)
end

controllers_path = Rails.root.join(entrypoint, "controllers")
application_controller_src = templates_path + "/app/javascript/controllers/application_controller.js.tt"
application_controller_path = controllers_path.join("application_controller.js")
application_src = templates_path + "/app/javascript/controllers/application.js.tt"
application_path = controllers_path.join("application.js")
index_src = templates_path + "/app/javascript/controllers/index.js.importmap.tt"
index_path = controllers_path.join("index.js")

# create entrypoint/controllers, as well as the index, application and application_controller
empty_directory controllers_path unless controllers_path.exist?

copy_file(application_controller_src, application_controller_path) unless application_controller_path.exist?

# configure Stimulus application superclass to import Action Cable consumer
friendly_application_path = application_path.relative_path_from(Rails.root).to_s
if application_path.exist?
  if File.read(application_path).include?("import consumer")
    say "✅ #{friendly_application_path} is present"
  else
    inject_into_file application_path, "import consumer from \"../channels/consumer\"\n", after: "import consumer from \"../channels/consumer\"\n", verbose: false
    inject_into_file application_path, "application.consumer = consumer\n", after: "application.debug = false\n", verbose: false
    say "#{friendly_application_path} has been updated to import the Action Cable consumer"
  end
else
  copy_file(application_src, application_path)
end

friendly_index_path = index_path.relative_path_from(Rails.root).to_s
if index_path.exist?
  if File.read(index_path) == File.read(index_src)
    say "✅ #{friendly_index_path} is present"
  else
    copy_file(index_path, "#{index_path}.bak", verbose: false)
    remove_file(index_path, verbose: false)
    copy_file(index_src, index_path, verbose: false)
    append_file("tmp/stimulus_reflex_installer/backups", "#{friendly_index_path}\n", verbose: false)
    say "#{friendly_index_path} has been created"
    say "❕ original index.js renamed index.js.bak", :green
  end
else
  copy_file(index_src, index_path)
end

create_file "tmp/stimulus_reflex_installer/importmap", verbose: false
