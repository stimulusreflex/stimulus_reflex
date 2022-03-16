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

export default [
  {
    external: [
      'morphdom',
      '@hotwired/stimulus',
      'cable_ready',
      '@rails/actioncable'
    ],
    input: 'javascript/index.js',
    output: [
      {
        name: 'StimulusReflex',
        file: 'dist/stimulus_reflex.umd.js',
        format: 'umd',
        sourcemap: true,
        exports: 'named',
        globals: {
          morphdom: 'morphdom',
          cable_ready: 'CableReady'
        },
        plugins: [pretty()]
      },
      {
        file: 'dist/stimulus_reflex.module.js',
        format: 'es',
        sourcemap: true,
        inlineDynamicImports: true,
        plugins: [pretty()]
      },
      {
        file: 'app/assets/javascripts/stimulus_reflex.js',
        format: 'es',
        inlineDynamicImports: true,
        plugins: [pretty()]
      },
      {
        file: 'app/assets/javascripts/stimulus_reflex.min.js',
        format: 'es',
        sourcemap: true,
        inlineDynamicImports: true,
        plugins: [minify()]
      }
    ],
    plugins: [commonjs(), resolve(), json()],
    watch: {
      include: 'javascript/**'
    }
  }
]
