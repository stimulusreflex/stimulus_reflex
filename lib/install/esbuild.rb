say "Installing esbuild-rails to support import route globbing"
run "yarn add esbuild-rails"

if (esbuild_config_path = Rails.root.join("esbuild.config.js")).exist?
  say <<~JS

    # const path = require('path')
    # const rails = require('esbuild-rails')

    # require("esbuild").build({
    #   entryPoints: ["application.js"],
    #   bundle: true,
    #   outdir: path.join(process.cwd(), "app/assets/builds"),
    #   absWorkingDir: path.join(process.cwd(), "app/javascript"),
    #   watch: process.argv.includes("--watch"),
    #   plugins: [rails()],
    # }).catch(() => process.exit(1))
    
  JS
  if !no?("esbuild.config.js already exists. Would you like to append the standard template as a comment?")
    append_to_file esbuild_config_path << ~JS

    # const path = require('path')
    # const rails = require('esbuild-rails')

    # require("esbuild").build({
    #   entryPoints: ["application.js"],
    #   bundle: true,
    #   outdir: path.join(process.cwd(), "app/assets/builds"),
    #   absWorkingDir: path.join(process.cwd(), "app/javascript"),
    #   watch: process.argv.includes("--watch"),
    #   plugins: [rails()],
    # }).catch(() => process.exit(1))
    JS
  end
else
  say "Creating esbuild.config.js with the standard template"
  create_file esbuild_config_path do
    <<~JS
      const path = require('path')
      const rails = require('esbuild-rails')

      require("esbuild").build({
        entryPoints: ["application.js"],
        bundle: true,
        outdir: path.join(process.cwd(), "app/assets/builds"),
        absWorkingDir: path.join(process.cwd(), "app/javascript"),
        watch: process.argv.includes("--watch"),
        plugins: [rails()],
      }).catch(() => process.exit(1))
    JS
  end

  run "npm set-script build \"node esbuild.config.js\""
end

# if (controller_index_path = Rails.root.join("app/javascript/controllers/index.js")).exist?
#   say "Configuring Stimulus controllers to use import globbing"
#   comment_lines controller_index_path, /HelloController/
#   append_to_file controller_index_path <<~JS
#     import controllers from "./**/*_controller.js"
#     controllers.forEach((controller) => {
#       application.register(controller.name, controller.module.default)
#     })
#   JS
# end

say "Configuring Action Cable channels to use import globbing"
if (channel_index_path = Rails.root.join("app/javascript/channels/index.js")).exist?
  append_to_file channel_index_path << ~JS
  import channels from "./**/*_channel.js"
  JS
end

create_file "tmp/stimulus_reflex_installer/esbuild_rails", verbose: false
