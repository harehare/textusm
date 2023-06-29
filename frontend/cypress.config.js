const { defineConfig } = require('cypress');

module.exports = defineConfig({
  e2e: {
    baseUrl: 'http://localhost:3000',
    specPattern: 'e2e/**/*.js',
    supportFile: false,
    defaultCommandTimeout: 10_000,
    retries: 5,
  },
});
