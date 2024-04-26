import { test, expect } from '@playwright/test';

test('Save the diagram to local and load it', async ({ page }) => {
  await page.goto('http://localhost:3000');

  await page.locator('[data-test-id="header-title"]').click();
  await page.locator('[data-test-id="header-input-title"]').fill('test');

  const monacoEditor = await page.locator('#editor');
  await monacoEditor.click();
  await page.keyboard.press('Meta+KeyA');
  await page.keyboard.type('test1\n');
  await page.keyboard.type('    test2\n');
  await page.keyboard.type('test3');

  await page.keyboard.press('Enter');
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
  await page.locator('.lime').click();
  await page.waitForTimeout(500);

  await expect(await page.locator('[data-test-id="card-6"] > .ts-card').getAttribute('fill')).toBe(`#00ff00`);
});
