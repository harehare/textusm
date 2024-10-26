import { test, expect } from '@playwright/test';

test('Create new diagram', async ({ page }) => {
  await page.goto('http://localhost:3000');

  await page.locator('[data-test-id="new-menu"]').click();
  await page.locator('[data-test-id="new-usm"]').click();

  await expect(await page.locator('monaco-editor').getAttribute('value')).toContain(
    `# user_activities: USER ACTIVITIES`
  );
});

test('Save the diagram to local and load it', async ({ page }) => {
  await page.goto('http://localhost:3000');

  await page.locator('[data-test-id="header-title"]').click();
  await page.locator('[data-test-id="header-input-title"]').fill('test');
  await page.locator('[data-test-id="header-input-title"]').press('Enter');

  const monacoEditor = await page.$('monaco-editor');
  await monacoEditor?.evaluate((node) => node.setAttribute('value', 'test1\n    test2\n    test3'));
  await page.waitForTimeout(500);

  await page.locator('[data-test-id="save-menu"]').click();
  await page.locator('[data-test-id="list-menu"]').click();
  await page.locator('[data-test-id="diagram-list-item"]').first().click();

  await expect(await page.locator('monaco-editor').getAttribute('value')).toContain(`test1`);
});

test('Change background color of user story map', async ({ page }) => {
  await page.goto('http://localhost:3000');

  await page.locator('[data-test-id="new-menu"]').first().click();
  await page.locator('[data-test-id="new-usm"]').first().click();
  await page.locator('[data-test-id="card-6"]').first().click();
  await page.locator('[data-test-id="background-color-context-menu"]').click();
  await page.locator('[data-test-id="color-lime"]').click();
  await page.waitForTimeout(500);

  await expect(await page.locator('[data-test-id="card-6"] > .ts-card').getAttribute('fill')).toBe(`#00ff00`);
});

test('Change foreground color of user story map', async ({ page }) => {
  await page.goto('http://localhost:3000');

  await page.locator('[data-test-id="new-menu"]').first().click();
  await page.locator('[data-test-id="new-usm"]').first().click();
  await page.locator('[data-test-id="card-6"]').first().click();
  await page.locator('[data-test-id="foreground-color-context-menu"]').click();
  await page.locator('[data-test-id="color-lime"]').click();
  await page.waitForTimeout(500);

  await expect(await page.locator('[data-test-id="card-6"] > text').getAttribute('color')).toBe(`#00ff00`);
});

test('Change background color settings', async ({ page }) => {
  await page.goto('http://localhost:3000');

  await page.locator("a[data-test-id='header-settings']").first().click();
  await page.locator("div[data-test-id='background-color']").first().click();
  await page.locator("div[data-test-id='background-color'] > div:nth-of-type(2) > div:first-child").first().click();
  await page.locator("div[data-test-id='header-back']").first().click();

  const backgroundColor = await page.locator('#usm').evaluate((el) => {
    return window.getComputedStyle(el).getPropertyValue('background-color');
  });

  await expect(backgroundColor).toBe(`rgb(254, 254, 254)`);
});

test('Save the diagram to remote and load it', async ({ page }) => {
  await page.goto('http://localhost:3000');

  await page.locator('[data-test-id="header-title"]').click();
  await page.locator('[data-test-id="header-input-title"]').fill('test');
  await page.locator('[data-test-id="header-input-title"]').press('Enter');

  const monacoEditor = await page.$('monaco-editor');
  await monacoEditor?.evaluate((node) => node.setAttribute('value', 'test1\n    test2\n    test3'));
  await page.waitForTimeout(500);
  await page.waitForFunction(() => {
    const editor = document.querySelector('monaco-editor');
    const applied = editor && editor.getAttribute('value') === 'test1\n    test2\n    test3';

    if (!applied) {
      editor?.setAttribute('value', 'test1\n    test2\n    test3');
    }

    return applied;
  });

  await page.locator('[data-test-id="header-signin"]').click();
  await page.locator('[data-test-id="google-menu-item"]').click();

  const popup = await page.waitForEvent('popup');
  await popup.waitForLoadState('networkidle');
  await popup.getByRole('button', { name: /add new account/i }).click();
  await popup.waitForLoadState('networkidle');
  await popup.getByRole('button', { name: /auto-generate/i }).click();
  await popup.getByRole('button', { name: /sign in/i }).click();

  await page.waitForSelector('[data-test-id="header-title"]');

  await page.locator('[data-test-id="save-menu"]').click();
  await page.waitForTimeout(1000);
  await page.waitForSelector('[data-test-id="list-menu"]');
  await page.locator('[data-test-id="list-menu"]').click();

  await page.waitForSelector('[data-test-id="diagram-list-item"]');
  await page.locator('[data-test-id="diagram-list-item"]').first().click();
  await page.waitForTimeout(500);

  await expect(await page.locator('monaco-editor').getAttribute('value')).toContain(`test1`);
});
