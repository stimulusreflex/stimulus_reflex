import resolve from '@rollup/plugin-node-resolve'
import commonjs from '@rollup/plugin-commonjs'
import json from '@rollup/plugin-json'
import { terser } from 'rollup-plugin-terser'

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

const minify = () => {
  return terser({
    mangle: true,
    compress: true
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
    morphdom: 'morphdom',
    cable_ready: 'CableReady',
    '@hotwired/stimulus': 'Stimulus'
  }
}

const distFolders = ['dist/', 'app/assets/javascripts/']

const output = distFolders
  .map(distFolder => [
    {
      ...umdConfig,
      file: `${distFolder}/stimulus_reflex.umd.js`,
      plugins: [pretty()]
    },
    {
      ...umdConfig,
      file: `${distFolder}/stimulus_reflex.umd.min.js`,
      sourcemap: true,
      plugins: [pretty()]
    },
    {
      ...esConfig,
      file: `${distFolder}/stimulus_reflex.js`,
      format: 'es',
      plugins: [pretty()]
    },
    {
      ...esConfig,
      file: `${distFolder}/stimulus_reflex.min.js`,
      sourcemap: true,
      plugins: [minify()]
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
    plugins: [commonjs(), resolve(), json()],
    watch: {
      include: 'javascript/**'
    }
  }
]
