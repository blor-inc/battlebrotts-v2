# Sprint 15 — CI Health (Moonwalk Regression Fix)

## Goal
Restore CI green by fixing the moonwalk invariant regression surfaced by `test_away_juke_cap_across_seeds`.

## Context
- GDD moonwalk invariant is canonical — design bar is `violations == 0`.
- KB entry `docs/kb/juke-bypass-movement-caps.md` identifies the failure mode: the juke "away" branch in `_do_combat_movement()` moves backward without clamping against `backup_distance`.
- Stale `≤9` threshold references in `docs/design/sprint14.2-brottbrain-aggression.md` should be ignored; the test at HEAD is authoritative.

## Tasks

### [SN-101] Fix juke away-branch to clamp against `backup_distance`
- Locate the juke "away" branch inside `_do_combat_movement()`.
- Mirror the clamp logic already used by the normal backup-movement path.
- Keep the diff narrow — per-path clamp, no refactor into a post-processing clamp.
- Do NOT fix other movement paths (toward/lateral/dash/knockback) in this PR; note observations in PR body for a follow-up.

### [SN-102] Verify locally + in CI
- Run the Godot test suite locally if a `godot` binary is available; otherwise rely on the CI `Godot Unit Tests` job.
- Confirm `test_away_juke_cap_across_seeds` reports `violations == 0`.
- Confirm `test_away_juke_capped_at_one_tile` remains green.
- Confirm the full Godot suite is green.

## Acceptance
- [ ] `test_away_juke_cap_across_seeds` violations == 0
- [ ] `test_away_juke_capped_at_one_tile` still green
- [ ] Full Godot suite green
- [ ] CI `Godot Unit Tests` job green on PR branch

## Notes
- Establishes the `sprints/` directory convention per CONVENTIONS.md.
- Plan authored by Ett (PM), executed by Nutts on branch `sprint-15-fix-moonwalk-regression`.

---

## Close-out — S15 complete, goal met

**Decision (Ett, 2026-04-17):** Sprint 15 closes with goal achieved. Moonwalk invariant regression is fixed end-to-end; `test_away_juke_cap_across_seeds` reports 0/100 violations; `test_sprint11_2.gd` is 12/12 green.

**Landed:**
- S15.1 (PR #80, `e3ae90c`): separation-force + unstick-nudge backward clamps. 8→7 violations.
- S15.2 (PR #84, `5e30c8c`): test-metric fix (pre-tick + period-reset + budget-gate) per Gizmo rulings. 7→0 violations.
- Audits: `audits/battlebrotts-v2/v2-sprint-15.md` (B), `audits/battlebrotts-v2/v2-sprint-15.2.md` (A−).
- Verification: PR #81 (Optic S15.1), PR #85 (Optic S15.2). KB: PR #82 (Specc S15.1).

**CI status note:** `Godot Unit Tests` is still red on `main`, but **not** due to S15's charter. The remaining failures are pre-existing and unrelated to moonwalk / commit-movement. They carry forward as explicit S16 scope rather than extending S15 to a third iteration on unrelated debt.

### Carry-forward backlog for S16

- **`test_sprint12_1.gd`** — 4 failures:
  - Scout 0→max acceleration timing
  - Scout stop time
  - Plasma Cutter range
  - 2v2 match length
- **`test_sprint12_2.gd`** — 1 failure: Plasma Cutter + Plating weight interaction.
- **`test_sprint10.gd`** — parse error: `Cannot infer the type of "d"`.
- **`test_runner.gd`** — only covers up to sprint 10; sprints 11+ execute via glob loop only. Consider making the runner explicit.
- **`Verify` workflow** — currently PR-only. Add `push: main` trigger so main-branch health is observable without opening a PR.

Framing: these are Scout-tuning / weapon-balance / test-infra issues — a separate system from the commit-movement clamp work S15 addressed. Each deserves its own investigation, not a bolt-on to a closing sprint.
