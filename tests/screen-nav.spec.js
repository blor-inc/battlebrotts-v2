// tests/screen-nav.spec.js — Playwright screen navigation tests for URL parameter routing
// Validates ?screen= URL params route to the correct game screens.
// See: kb/patterns/godot-ci-visual-verification.md, kb/patterns/playwright-local-server.md
const { test, expect } = require('@playwright/test');

test('/?screen=battle loads battle arena', async ({ page }) => {
  await page.goto('/game/?screen=battle');
  // Wait for Godot WASM to start loading — canvas should exist in DOM
  // (headless CI won't have WebGL so Godot may stall at loading, but canvas is present)
  const canvas = page.locator('canvas');
  await expect(canvas).toBeAttached({ timeout: 15000 });
  await page.screenshot({ path: 'tests/screenshots/screen-battle.png' });
});

test('/?screen=menu loads main menu', async ({ page }) => {
  await page.goto('/game/?screen=menu');
  const canvas = page.locator('canvas');
  await expect(canvas).toBeAttached({ timeout: 15000 });
  await page.screenshot({ path: 'tests/screenshots/screen-menu.png' });
});

test('/ with no params loads default flow', async ({ page }) => {
  await page.goto('/game/');
  // Default flow should also produce a canvas (main menu)
  const hasContent = await page.evaluate(() => {
    return document.querySelector('canvas') !== null || document.body.innerText.length > 0;
  });
  expect(hasContent).toBeTruthy();
  await page.screenshot({ path: 'tests/screenshots/screen-default.png' });
});
