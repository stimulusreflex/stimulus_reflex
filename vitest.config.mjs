import { defineConfig } from 'vitest/config'
import { playwright } from '@vitest/browser-playwright'

const filteredLogs = [
  'Lit is in dev mode. Not recommended for production! See https://lit.dev/msg/dev-mode for more information.'
]

export default defineConfig({
  test: {
    globals: true,
    include: ['javascript/test/**/*.test.js'],
    onConsoleLog: log => !filteredLogs.some(l => log.includes(l)),
    browser: {
      enabled: true,
      provider: playwright(),
      headless: true,
      instances: [{ browser: 'chromium' }]
    }
  }
})
