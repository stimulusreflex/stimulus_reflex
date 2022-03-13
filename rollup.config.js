import resolve from '@rollup/plugin-node-resolve'
import commonjs from '@rollup/plugin-commonjs'
import json from '@rollup/plugin-json'

const basePlugins = [
  resolve(),
  commonjs(),
  json()
]

export default [
  {
    external: ['morphdom'],
    input: 'javascript/index.js',
    output: [
      {
        name: 'StimulusReflex',
        file: 'dist/stimulus_reflex.umd.js',
        format: 'umd',
        sourcemap: true,
        exports: 'named',
        globals: { morphdom: 'morphdom' }
      },
      {
        file: 'dist/stimulus_reflex.module.js',
        format: 'es',
        sourcemap: true
      }
    ],
    plugins: basePlugins,
    watch: {
      include: 'javascript/**'
    }
  }
]
