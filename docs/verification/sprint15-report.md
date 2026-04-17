# Sprint 15 Verification — Moonwalk CI Fix

**Verifier:** Optic
**Commit:** `e3ae90c` on `main` (PR #80 merge commit; PR head `4cf20ed`)
**Date:** 2026-04-17

## Headline

**PARTIAL PASS.** Sprint 15 landed cleanly on `main`. Option-1 clamps reduced
`test_away_juke_cap_across_seeds` violations 8→7 of 100 and introduced no regressions, but the
zero-violation bar is **not** met. Residual 7 violations are the test-metric artifact flagged by
Boltz (post-tick `to_target` sampling on COMMIT-crossover), not a code regression. Debug harness
works and reproduces the exact 7 failing seeds.

## Summary Table

| # | Check | Result |
|---|---|---|
| 1 | Full Godot unit-test suite (local headless, CI glob) | **PARTIAL PASS** — only known failure present |
| 2 | CI `Godot Unit Tests` job on PR #80 (`4cf20ed`) | **FAILURE** (expected — same known test) |
| 3 | CI `Playwright Smoke Tests` on PR #80 | **PASS** |
| 4 | Debug harness `tests/harness/debug_moonwalk.gd` | **PASS** — runs, reports 7/100, prints seed list |
| 5 | Combat sim / vision screenshots | **SKIPPED** — CI-health fix, not a gameplay/visual change |

## Key Numbers

- `test_sprint11_2.gd :: test_away_juke_cap_across_seeds` → **7/100 violations**
- Baseline pre-sprint: **8/100**
- Improvement: **-1 violation (-12.5%)**. Matches Nutts' local runs exactly (deterministic).
- `test_sprint11_2.gd` totals: **11 passed, 1 failed of 12** (the one failure is the above).

### Failing seeds (from debug harness, for Gizmo/Ett)

```
seed=2  violated_at_tick=44 max_run=38.6
seed=23 violated_at_tick=40 max_run=79.8
seed=45 violated_at_tick=92 max_run=46.4
seed=63 violated_at_tick=39 max_run=52.0
seed=67 violated_at_tick=63 max_run=39.0
seed=80 violated_at_tick=30 max_run=85.2
seed=84 violated_at_tick=32 max_run=67.3
```

## Details

### 1. Local headless test suite (matches CI runner)

Ran CI's exact command sequence on `e3ae90c`:

```
godot --headless --path godot/ --script res://tests/test_runner.gd
for f in godot/tests/test_sprint1[0-9]_*.gd godot/tests/test_sprint1[0-9].gd; do
  godot --headless --path godot/ --script "res://tests/$(basename $f)"
done
```

Raw log: `test-output.txt`.

**Aggregated results:**

| Script | Pass/Fail/Total | Notes |
|---|---|---|
| `test_runner.gd` | 72 / 0 / 72 | green |
| `test_sprint11.gd` | 9 / 0 / 9 | green (incl. 7/100 moonwalk check that passes its own threshold) |
| `test_sprint11_2.gd` | **11 / 1 / 12** | **failure on `test_away_juke_cap_across_seeds` (7/100)** |
| `test_sprint12_1.gd` | 26 / 4 / 30 | 4 failures — **pre-existing** (present at `7567fb5^`, before sprint 15) |
| `test_sprint12_2.gd` | 32 / 1 / 33 | 1 failure — **pre-existing** |
| `test_sprint12_3.gd` | 42 / 0 / 42 | green |
| `test_sprint12_4.gd` | 45 / 0 / 45 | green |
| `test_sprint12_5.gd` | 27 / 0 / 27 | green |
| `test_sprint13_2.gd` | 11 / 0 / 11 | green |
| `test_sprint13_3.gd` | 33 / 0 / 33 | green |
| `test_sprint13_4.gd` | 42 / 0 / 42 | green |
| `test_sprint13_5.gd` | 32 / 0 / 32 | green |
| `test_sprint13_6.gd` | 61 / 0 / 61 | green |
| `test_sprint13_7.gd` | 74 / 0 / 74 | green |
| `test_sprint13_8_modal_hardening.gd` | 15 / 0 / 15 | green |
| `test_sprint13_8_toast.gd` | 12 / 0 / 12 | green |
| `test_sprint13_9.gd` | 17 / 0 / 17 | green |
| `test_sprint13_10.gd` | 5 / 0 / 5 | green |
| `test_sprint14_1.gd` | 19 / 0 / 19 | green |
| `test_sprint14_1_nav.gd` | 5 / 0 / 5 | green |
| `test_sprint10.gd` | — | **Parse error** (`Cannot infer the type of "d"` at line 87). **Pre-existing** — fails identically at `7567fb5^`. Not triggered by sprint 15. |

**Internal-assert failures in `test_sprint12_1.gd` / `test_sprint12_2.gd` / parse error in `test_sprint10.gd` do not fail the CI step** (those scripts exit 0 regardless). CI exit-code failure in sprint 15 comes solely from `test_sprint11_2.gd`.

### 2. CI on PR #80

Latest verify run for head `4cf20ed`:
- Run ID: `24575921135` — <https://github.com/brott-studio/civil-war-not-relevant> — `Verify`
- **Godot Unit Tests** → `conclusion=failure`, exit 1 immediately after `test_sprint11_2.gd` reports `11 passed, 1 failed out of 12` (line 377 of job log).
- **Playwright Smoke Tests** → `conclusion=success`.

Main branch only runs `Build & Deploy` (also in_progress/success for `e3ae90c`); `Verify` is PR-gated, so there's no independent post-merge CI run to check.

### 3. Debug harness

`tests/harness/debug_moonwalk.gd` runs cleanly, scans seeds 0–99, prints the 7 offending seeds with tick + max-run, and totals. Immediately useful for Gizmo/Ett when investigating the measurement-vs-mechanic question. Output archived in `harness-output.txt`.

### 4. Regressions

**None.** All pre-existing green suites remain green. Pre-existing `test_sprint12_1`, `test_sprint12_2`, and `test_sprint10` failures/parse errors are reproducible at the pre-sprint baseline (`7567fb5^`) and are **not** caused by Option-1 clamps.

## Open Items (for Gizmo / Ett next iteration)

- **Pre-tick vs post-tick `to_target` measurement.** Boltz's analysis attributes the residual 7
  violations to the test sampling post-tick: on a COMMIT-crossover tick, bot passes through
  target → `to_target` flips sign → harness registers forward crossover as backward motion.
  Gizmo should rule on whether the correct measurement is pre-tick (before movement is applied)
  or post-tick with a crossover-aware filter.
- **COMMIT-crossover as residual signal.** The 7 seeds cluster around COMMIT-phase crossover
  events (ticks 30–92, spread across early/mid match). Not a code regression; a metric artifact.
- **Zero-violation bar.** Until the measurement is fixed, `test_away_juke_cap_across_seeds`
  cannot pass on strict `violations == 0`. Either relax the assertion threshold (e.g., `<=
  0` → `<= 2` with a tracking issue) or switch to pre-tick measurement.
- **Unrelated tech debt surfaced by this verification:**
  - `test_sprint12_1.gd` — 4 stale-expectation failures (accel/decel timing eps, Plasma Cutter
    range, 2v2 100s timeout) from earlier balance changes that were never re-baselined.
  - `test_sprint12_2.gd` — 1 stale weight-bar numeric assertion.
  - `test_sprint10.gd` — Godot 4.4 static-typing warning-as-error parse failure at line 87.
  None of these block CI today (scripts exit 0), but they're silently rotting. Worth a sweep.

## Artifacts

- `test-output.txt` — full headless test-suite log
- `harness-output.txt` — debug_moonwalk.gd output (failing seeds)
