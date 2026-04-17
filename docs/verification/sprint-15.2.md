# Sprint 15.2 Verification Report

**Verifier:** Optic
**Date:** 2026-04-17
**Subject:** [SN-103] Fix moonwalk metric (squash commit `5e30c8c`, merged via PR #84)
**Headline:** ✅ **PASS** — target met (0/100 moonwalk violations, 12/12 test_sprint11_2.gd), scope gate held, no S15.2 regressions. Pre-existing tech-debt failures carry forward unchanged.

## Summary

| Check | Result |
|---|---|
| `test_sprint11_2.gd` 12/12 pass | ✅ |
| `test_away_juke_cap_across_seeds` — `No moonwalk violations (0/100)` | ✅ |
| `test_away_juke_capped_at_one_tile` | ✅ PASS (`backup_distance capped: 0.0 px (max 32)`) |
| Debug harness (`tests/harness/debug_moonwalk.gd`) — 100 seeds | ✅ `=== Total violations: 0/100 ===` |
| Previously-failing seeds 2, 23, 45, 63, 67, 80, 84 | ✅ all clean (full 0..99 scan passes) |
| `test_runner.gd` | ✅ 72 passed, 0 failed |
| Full sprint-test sweep (sprint 11..14) | ✅ green except carried-forward tech debt (see below) |
| Scope gate (`combat_sim.gd` untouched in `5e30c8c`) | ✅ |
| CI on PR #84 head (`fef5211`) — Godot Unit Tests | ⚠️ "failure" — bails on pre-existing `test_sprint12_1.gd` 4 failures (not a S15.2 regression; identical behavior on pre-S15.2 main) |
| Post-merge main CI (`Build & Deploy` on tip `f31d746`) | ✅ success |

## Scope gate

`git log 5e30c8c --name-only` — touched files:

- `docs/design/sprint15-moonwalk-metric-ruling.md`
- `godot/tests/harness/debug_moonwalk.gd` (+ `.uid`)
- `godot/tests/test_sprint11_2.gd`
- `godot/tests/test_sprint13_10.gd.uid`
- `godot/tests/test_sprint14_1.gd.uid` (+ `_nav.gd.uid`)
- `godot/ui/league_complete_modal.gd.uid` (uid only — no code)
- `sprints/sprint-15.2.md`

✅ **Scope gate holds** — no runtime code changed. `combat_sim.gd` diff vs `main` is empty.

## Target test: `tests/test_sprint11_2.gd`

```
=== BattleBrotts Sprint 11.2 Test Suite ===

-- Away Juke Cap (direct test) --
  PASS: backup_distance capped: 0.0 px (max 32)

-- Away Juke Cap (100 seeds) --
  PASS: No moonwalk violations (0/100)

-- Hit Rate Instrumentation --
  PASS: Hit rates recorded for 1 weapon(s)
  PASS: Hit rate for Plasma Cutter: 0.42 (valid range)
  PASS: Total shots fired: 38 (>0)

-- TTK Instrumentation --
  PASS: First engagement tick recorded: 9
  PASS: TTK recorded for 1 bot(s)
  PASS: TTK for Scout_1: 9.1s (non-negative)

--- Results ---
12 passed, 0 failed out of 12
```

Full log: `docs/verification/sprint-15.2/test_sprint11_2.log`.

## Debug harness: `tests/harness/debug_moonwalk.gd`

```
=== Moonwalk seed scan (0..99) ===
=== Total violations: 0/100 ===
```

All 100 seeds clean. Previously-failing seeds (2, 23, 45, 63, 67, 80, 84) no longer flag. Full log: `docs/verification/sprint-15.2/debug_moonwalk.log`.

## Regression sweep

Reproduced the `Verify` workflow locally:

1. `godot --headless --path godot/ --script res://tests/test_runner.gd` → **72 passed, 0 failed**.
2. Glob loop over `test_sprint1[0-9]*.gd` (same as CI):

| Test | Result |
|---|---|
| `test_sprint11_2.gd` | 12 / 0 |
| `test_sprint12_1.gd` | **26 / 4** (pre-existing) |
| `test_sprint12_2.gd` | **32 / 1** (pre-existing) |
| `test_sprint12_3.gd` | 42 / 0 |
| `test_sprint12_4.gd` | 45 / 0 |
| `test_sprint12_5.gd` | 27 / 0 |
| `test_sprint13_10.gd` | 5 / 0 |
| `test_sprint13_2.gd` | 11 / 0 |
| `test_sprint13_3.gd` | 33 / 0 |
| `test_sprint13_4.gd` | 42 / 0 |
| `test_sprint13_5.gd` | 32 / 0 |
| `test_sprint13_6.gd` | 61 / 0 |
| `test_sprint13_7.gd` | 74 / 0 |
| `test_sprint13_8_modal_hardening.gd` | 15 / 0 |
| `test_sprint13_8_toast.gd` | 12 / 0 |
| `test_sprint13_9.gd` | 17 / 0 |
| `test_sprint14_1.gd` | 19 / 0 |
| `test_sprint14_1_nav.gd` | 5 / 0 |
| `test_sprint10.gd` | **Parse error** (pre-existing) |
| `test_sprint11.gd` | 9 / 0 |

Full log: `docs/verification/sprint-15.2/sprint_tests.log`.

## Pre-existing tech debt (carried forward — NOT S15.2 regressions)

Same failures and gaps as documented in Optic's S15.1 verification report (PR #81). All predate S15.1 and exist on pre-S15.2 main; S15.2 touched tests only (`test_sprint11_2.gd` + `debug_moonwalk.gd`) so cannot have introduced or closed any of these.

1. **`test_sprint12_1.gd` — 4 failures:**
   - `Scout 0→max in ~0.33s (got 0.4000, expected 0.3300, eps 0.0500)`
   - `Scout stops in ~0.25s (got 0.3000, expected 0.2500, eps 0.0500)`
   - `Plasma Cutter does NOT fire at 2.6 tiles`
   - `2v2 match NOT over at 100s`
2. **`test_sprint12_2.gd` — 1 failure:** `Plasma Cutter (8) + Plating (5) = 13 kg`.
3. **`test_sprint10.gd` — parse error:** `Cannot infer the type of "d" variable because the value doesn't have a set type.` (warning treated as error).
4. **`test_runner.gd` only covers up to Sprint 10** — sprints 11+ are picked up only by the CI glob loop, not by the runner itself.
5. **`Verify` workflow is PR-only** — main branch runs only `Build & Deploy` (no Godot unit tests post-merge). Confirmed via API: runs on `5e30c8c` were `Build & Deploy` only (cancelled by concurrency as subsequent merges landed).
6. **Runtime parse warning:** `arena/arena_renderer.gd` — `The variable type is being inferred from a Variant value, so it will be typed as Variant. (Warning treated as error.)` — observed only in CI (non-fatal locally). Independent of S15.2.

Recommend **Specc** capture these in KB / tech-debt backlog for **Ett** routing.

## CI

- **PR #84 head `fef5211` — `Godot Unit Tests`:** ❌ `failure`. Inspected log (`/tmp/job_84.log`): fails inside the glob loop on `test_sprint12_1.gd` (`exit 1` via `|| exit 1`) after the pre-existing 4 failures. `test_sprint11_2.gd` ran successfully (`12 passed, 0 failed`) before the bail. **This is identical to pre-S15.2 behavior and not a S15.2 regression.**
- **PR #84 head `fef5211` — `Playwright Smoke Tests`:** ✅ success.
- **Post-merge `Build & Deploy` runs on main:**
  - `5e30c8c` — `cancelled` (superseded by next merge under `deploy` concurrency group).
  - `b58a51a` — `cancelled` (superseded).
  - `f31d746` (current main tip) — ✅ **success**.

No post-merge Godot test run exists for `5e30c8c` itself because `Verify` is PR-only; local reproduction above provides equivalent confidence.

## Artifacts

Raw test output under `docs/verification/sprint-15.2/`:
- `test_sprint11_2.log`
- `debug_moonwalk.log`
- `test_runner.log`
- `sprint_tests.log`

## Verdict

✅ **PASS.** S15.2 achieves its goal (0/100 moonwalk violations, 12/12 pass on `test_sprint11_2.gd`), preserves the scope gate (no runtime code touched), and introduces zero regressions. Pre-existing tech debt is unchanged and is Specc/Ett's follow-up, not a blocker for S15.2.
