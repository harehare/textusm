import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: Boolean(process.env.CI),
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'line',
  use: {
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
  ],
  webServer: [
    {
      command: 'npm run dev:frontend',
      url: 'http://localhost:3000',
      reuseExistingServer: !process.env.CI,
      timeout: 10 * 60 * 1000,
      stdout: 'pipe',
      stderr: 'pipe',
    },
    {
      command: 'cd ../backend && DB_TYPE=sqlite FIREBASE_AUTH_EMULATOR_HOST="localhost:9099" USE_HTTPS=0 just run',
      url: 'http://localhost:8081/healthcheck',
      reuseExistingServer: !process.env.CI,
      timeout: 10 * 60 * 1000,
      stdout: 'pipe',
      stderr: 'pipe',
    },
  ],
});
