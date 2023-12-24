import { defineConfig } from 'cypress'

export default defineConfig({
  e2e: {
    baseUrl: 'http://127.0.0.1:8000',
    specPattern: './cypress/e2e/**/*.cy.{js,jsx,ts,tsx,spec}',
    supportFile: false
  },
})
