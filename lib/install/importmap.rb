say "Pin StimulusReflex, CableReady and morphdom"
pin "@rails/actioncable", to: "actioncable.esm.js"
pin "cable_ready", to: "https://ga.jspm.io/npm:cable_ready@5.0.0-pre9/dist/cable_ready.min.js"
pin "stimulus_reflex", to: "https://ga.jspm.io/npm:stimulus_reflex@3.5.0-pre9/dist/stimulus_reflex.min.js"
pin "morphdom", to: "https://ga.jspm.io/npm:morphdom@2.6.1/dist/morphdom.js"

create_file "tmp/stimulus_reflex_installer/importmap", verbose: false
