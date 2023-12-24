import { defineConfig } from 'cypress'

export default defineConfig({
  e2e: {
    setupNodeEvents(on, config) {},
    baseUrl: 'http://127.0.0.1:8000',
    specPattern: './cypress/integration/**/*.cy.{js,jsx,ts,tsx,spec}',
    supportFile: false
  },
})
