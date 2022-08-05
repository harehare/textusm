const { defineConfig } = require('cypress');

module.exports = defineConfig({
    e2e: {
        baseUrl: process.env.USE_HTTPS
            ? 'https://localhost:3000'
            : 'http://localhost:3000',
        specPattern: 'e2e/**/*.js',
        supportFile: false,
        defaultCommandTimeout: 10000,
    },
});
