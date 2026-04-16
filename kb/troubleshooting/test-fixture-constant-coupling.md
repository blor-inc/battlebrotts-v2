# KB: Test Fixture Coupling to Gameplay Constants

**Source:** Sprint 12.1 — PR #48 required 4 fix rounds
**Date:** 2026-04-16
**Category:** Troubleshooting

## Problem

When gameplay constants change (overtime thresholds, arena shrink timing, timeout values), tests that use default bot positions or hardcoded timing expectations break in non-obvious, cascading ways.

### Sprint 12.1 Case Study

Changing 1v1 overtime from 60s to 45s caused arena shrink to start 15s earlier. Test bots placed at default edge-ish positions got killed by the boundary before the timeout test could complete. This required 4 separate fix commits:

1. Update stale timeout constant (test used old 60s value)
2. Center timeout test bots so they survive arena shrink
3. Center bots in test_runner.gd (shared fixture had same issue)
4. Fix rng_seed test that also depended on old timing

Each fix exposed the next layer of implicit coupling.

## Root Cause

Tests implicitly depend on production gameplay constants:
- **Bot starting positions** assume arena boundary won't reach them during the test
- **Timing assertions** hardcode expected tick counts derived from constants
- **Test runners** use shared setup that couples to arena geometry and timing

## Prevention

### For test authors:
1. **Center test bots** at arena center (0,0) unless testing position-specific behavior
2. **Use local constants** in tests — don't derive expected values from production constants at runtime; hardcode the expected values so tests break obviously when constants change
3. **Isolate timing tests** — if testing timeout behavior, disable arena shrink for that test or set a very large arena
4. **Document constant dependencies** — if a test relies on a specific production constant value, comment it: `# Assumes OVERTIME_TICKS_1V1 = 450`

### For feature developers:
1. **When changing gameplay constants**, grep tests for the old values
2. **Run full test suite** before opening PR, not just the new sub-sprint tests
3. **Consider a "constants changed" checklist**: overtime, arena size, tick rate, HP values — each affects test fixtures

## Related KB Entries
- `kb/patterns/tick-rate-pacing-lever.md` — tick rate halving (Sprint 4) caused similar cascading test updates
- `kb/patterns/shrinking-arena-pacing.md` — arena shrink mechanics that interact with bot positioning
