# Sprint 7 Verification Report — [S7-002]

**Verifier:** Optic  
**Date:** 2026-04-16  
**Branch:** `optic/S7-002-verify`  
**Base:** `main@9cb7973` (includes S7-001 bug fixes PR #31)

---

## S7-001 Changes Under Verification

1. **`brottbrain_screen.gd`** — `max()` → `maxi()` with explicit `int` type annotation (line 139)
2. **`kb/troubleshooting/godot-web-export.md`** — cleaned up contradictory advice

---

## 1. Headless Tests — Variant Type Error Fix

### S5 Test Suite (`test_sprint5.gd`)
**Result: ❌ FAILED (pre-fix) → ✅ PASS (post-fix)**

The S7-001 fix resolved the `brottbrain_screen.gd` Variant inference error, but `test_sprint5.gd` itself had the **same pattern** at lines 54 and 58:
```gdscript
var settings := ProjectSettings.get_setting(...)  # Variant inference → error
```
Fixed to `var settings: Variant = ...` in this verification branch. After fix: **13/13 passed**.

### S6 Test Suite (`test_sprint6.gd`)
**Result: ✅ 19/19 PASSED**

No Variant issues. Minor non-fatal error on `arena_renderer_setup` (property assignment on RefCounted) — pre-existing, not a regression.

### Core Test Runner (`test_runner.gd`)
**Result: ⚠️ 65/71 passed, 6 failed**

The 6 failures are **pre-existing data mismatches** (not regressions from S7-001):
- Scout HP: expected 200, got 150
- Brawler HP: expected 300, got 225
- Fortress HP: expected 360, got 270
- Energy regen: expected +5/s, got +10/s
- Match timeout: expected tick 2400, got 900
- Repair Nanites: expected +3 HP/s, got +6 HP/s

These reflect balance changes from earlier sprints that were never synced to `test_runner.gd`. **Not caused by S7-001.**

---

## 2. Playwright — Main Menu + Shop Rendering

**Result: ✅ 3/3 PASSED**

| Test | Status |
|------|--------|
| Dashboard loads with content | ✅ |
| Game page loads | ✅ |
| Game page has canvas or placeholder | ✅ |

Dashboard and game pages render correctly via local serve.

---

## 3. Combat Batch Simulations (540 matches)

**Result: ✅ Pacing holds — no regressions**

| Matchup | Win A | Win B | Draws | Notes |
|---------|-------|-------|-------|-------|
| Scout vs Scout | 83% | 17% | 0% | Seed-dependent asymmetry |
| Scout vs Brawler | 0% | 100% | 0% | Expected: Brawler dominates |
| Scout vs Fortress | 0% | 100% | 0% | Expected: Fortress dominates |
| Brawler vs Brawler | 50% | 42% | 8% | Balanced mirror |
| Brawler vs Fortress | 0% | 100% | 0% | Fortress dominates |
| Fortress vs Fortress | 5% | 5% | 90% | Draws expected (tank vs tank) |

**Overall chassis win rates:** Scout 28%, Brawler 50%, Fortress 68%

Hierarchy: Fortress > Brawler > Scout — consistent with previous sprints. The `maxi()` fix had no impact on combat logic (expected, since it only affects UI layout).

---

## 4. Test Harness

**Result: ✅ Working**

Ran `tools/test_harness.gd` with default `commands.json` (10 commands):
- Navigated: main_menu → shop → loadout → arena
- Arena match started (Player Bot vs Rusty)
- Simulated 700 ticks, overtime activated
- State log saved to `tools/state_log.json`
- Screenshots saved (placeholder PNGs in headless mode — expected)

---

## Summary

| Check | Status | Notes |
|-------|--------|-------|
| Variant type error fix | ✅ | `brottbrain_screen.gd` fixed; `test_sprint5.gd` also needed same fix |
| S5 tests | ✅ | 13/13 after test file fix |
| S6 tests | ✅ | 19/19 |
| Core tests | ⚠️ | 65/71 — 6 pre-existing data mismatches (not S7 regressions) |
| Playwright smoke | ✅ | 3/3 |
| Combat sims (540) | ✅ | Pacing unchanged |
| Test harness | ✅ | Runs correctly |

### Verdict: **S7-001 VERIFIED** ✅

The `maxi()` fix resolves the Variant inference error in production code. Test files needed the same treatment — included in this PR.

### Recommendations
- **Update `test_runner.gd`** data expectations to match current balance values (6 stale assertions from earlier sprint balance changes)
- Consider a lint pass for remaining `var x := SomeVariantReturningFunc()` patterns
