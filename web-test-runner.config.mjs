import rollupJson from '@rollup/plugin-json'
import { fromRollup } from '@web/dev-server-rollup'

const json = fromRollup(rollupJson)

const filteredLogs = [
  'Lit is in dev mode. Not recommended for production! See https://lit.dev/msg/dev-mode for more information.'
]

const filterBrowserLogs = (log) => {
  for (const arg of log.args) {
    if (typeof arg === 'string' && filteredLogs.some(l => arg.includes(l))) {
      return false
    }
  }
  return true
}

export default {
  nodeResolve: true,
  filterBrowserLogs,
  mimeTypes: {
    '**/*.json': 'js'
  },
  plugins: [json({})]
}
