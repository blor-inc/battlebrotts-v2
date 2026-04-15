# Playwright Local Server Pattern

**Source:** Sprint 0 (Patch, S0-001)

## Pattern
Use Playwright's built-in `webServer` config to auto-start a local server for tests, rather than requiring manual server setup or testing against live URLs.

## Implementation
```js
// playwright.config.js
webServer: {
  command: 'npx serve -l 8080 -s _site',
  port: 8080,
  reuseExistingServer: true,
  timeout: 10000,
}
```

## Why
- Tests are reproducible (not dependent on deploy state)
- CI doesn't need a separate server step
- `reuseExistingServer: true` allows running tests locally while dev server is up

## Anti-pattern
Testing against live URLs (e.g., `github.io`) in the verify stage couples verification to prior deployment. Use local server for verify; live URL tests are post-deploy smoke tests only.
