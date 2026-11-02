import { defineConfig } from 'vitest/config'

const filteredLogs = [
  'Lit is in dev mode. Not recommended for production! See https://lit.dev/msg/dev-mode for more information.'
]

export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    include: ['javascript/test/**/*.test.js'],
    onConsoleLog: log => !filteredLogs.some(l => log.includes(l))
  }
})
