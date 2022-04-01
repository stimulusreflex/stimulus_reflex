import rollupJson from '@rollup/plugin-json'
import { fromRollup } from '@web/dev-server-rollup'

const json = fromRollup(rollupJson)

export default {
  nodeResolve: true,
  mimeTypes: {
    '**/*.json': 'js'
  },
  plugins: [json({})]
}
