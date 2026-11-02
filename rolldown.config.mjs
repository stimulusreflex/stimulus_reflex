import { defineConfig } from 'rolldown'

const comments = { legal: true, annotation: true, jsdoc: false }

const esConfig = {
  format: 'es',
  codeSplitting: false,
  comments
}

const umdConfig = {
  name: 'StimulusReflex',
  format: 'umd',
  exports: 'named',
  comments,
  strict: false,
  intro: '"use strict";',
  globals: {
    '@rails/actioncable': 'ActionCable',
    morphdom: 'morphdom',
    cable_ready: 'CableReady',
    '@hotwired/stimulus': 'Stimulus'
  }
}

const baseName = 'stimulus_reflex'
const distFolders = ['dist', 'app/assets/javascripts']

const output = distFolders
  .map(distFolder => [
    {
      ...umdConfig,
      file: `${distFolder}/${baseName}.umd.js`
    },
    {
      ...esConfig,
      file: `${distFolder}/${baseName}.js`
    }
  ])
  .flat()

export default defineConfig({
  external: [
    'morphdom',
    '@hotwired/stimulus',
    'cable_ready',
    '@rails/actioncable'
  ],
  input: 'javascript/index.js',
  output,
  watch: {
    include: 'javascript/**'
  }
})
