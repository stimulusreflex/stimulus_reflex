import resolve from '@rollup/plugin-node-resolve'
import json from '@rollup/plugin-json'
import terser from '@rollup/plugin-terser'

const pretty = () => {
  return terser({
    mangle: false,
    compress: false,
    format: {
      beautify: true,
      indent_level: 2
    }
  })
}

const esConfig = {
  format: 'es',
  inlineDynamicImports: true
}

const umdConfig = {
  name: 'StimulusReflex',
  format: 'umd',
  exports: 'named',
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
      file: `${distFolder}/${baseName}.umd.js`,
      plugins: [pretty()]
    },
    {
      ...esConfig,
      file: `${distFolder}/${baseName}.js`,
      format: 'es',
      plugins: [pretty()]
    }
  ])
  .flat()

export default [
  {
    external: [
      'morphdom',
      '@hotwired/stimulus',
      'cable_ready',
      '@rails/actioncable'
    ],
    input: 'javascript/index.js',
    output,
    plugins: [resolve(), json()],
    watch: {
      include: 'javascript/**'
    }
  }
]
