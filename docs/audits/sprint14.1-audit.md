# Sprint 14.1 — Post-Merge Audit

**Auditor:** Specc
**Date:** 2026-04-17
**Merge:** PR #74, squash commit `5f97cab` on `main`, 2026-04-16 ~21:50 EDT
**Scope:** 10 files changed, +575 / −2 lines across two slices (A: progression UX, B: wall-stuck nav fix)

---

## 1. Summary

Sprint 14.1 shipped two player-facing improvements: a bronze league-complete progression moment plus a mid-match concede pill (Slice A), and a fix for brotts freezing against walls in close-quarters combat (Slice B). Slice A was single-pass green and unremarkable. Slice B was the dramatic one — it surfaced a real over-aggressive-detector bug in Boltz's first review, triggered a role-drift incident where the studio lead began committing IC code directly, and ultimately shipped clean after a force-push revert and a re-delegation to Nutts-B. The ship is healthy: hard-bar regression tests for the actual wall-freeze bug hold, with a documented ~8/100 residual producing minor wrong-direction arcs in dense Scout-vs-Scout combat. Two non-blocking Boltz nits and one optional detector restructure carry forward to S14.2. A process gap — no Specc audit was run between sub-sprints — was flagged by the Human Creative Director (HCD) and is closed by this document. Going forward, the Specc audit is a hard gate between sub-sprints: no N+1 work begins until N's audit is committed to the repo.

---

## 2. What shipped

### Slice A — Bronze progression UI + concede button

**Owner:** Nutts-A. Single-pass green, Boltz approved first round, no drama.

**Files:**

- `godot/ui/league_complete_modal.gd` (+90, new)
- `godot/ui/league_complete_modal.tscn` (+5, new)
- `godot/game/game_state.gd` (+16)
- `godot/game_main.gd` (+80)
- `godot/tests/test_sprint14_1.gd` (+145, new — 19 tests)

**Deliverables:**

- A league-complete modal that fires when the player finishes the bronze league, giving the progression moment an explicit UI cue instead of a silent state transition.
- A concede pill in the combat UI — a mid-match surrender affordance for fights the player no longer wants to finish.
- 19-test coverage file pinning modal behavior, state wiring, and concede flow.

**Player POV:** Finishing a league now feels like an accomplishment rather than a silent counter increment. Stuck or unwinnable fights can be ended cleanly without a rage-quit to the desktop.

### Slice B — Wall-stuck nav fix

**Owner:** Nutts-B. Two review rounds, one revert, one re-delegation. Shipped.

**Files:**

- `godot/combat/combat_sim.gd` (+107 — geometry + LOS freeze detection, unstick-with-repath)
- `godot/combat/brott_state.gd` (+6 — stuck-state fields)
- `godot/tests/test_sprint14_1_nav.gd` (+117, new — 5 tests: T1 long-freeze, T2 re-path, T3 stuck-timing, T4 direction, T5 threshold)
- `godot/tests/test_sprint11.gd` (+8 / −2 — AC6 threshold relaxed from `==0` to `≤10`)
- `.github/workflows/verify.yml` (+3 / −1 — test glob fix)

**Deliverables:**

- A geometry-gated detector that only evaluates stuck state when the bot is actually near wall geometry, avoiding false-positives during routine close-quarters orbit.
- An unstick-with-repath escape path that falls back toward the target (not perpendicular to it, which was the moonwalk producer in round 1).
- Reduced `UNSTICK_NUDGE_PX_PER_TICK` from 14 → 7 to shrink the straight-line backup signature.
- Hard-bar regression tests (T1/T2/T4) pinning the actual playtest bug.
- CI test-glob repair so S14-prefixed tests are actually executed by GitHub Actions.

**Player POV:** Brotts no longer freeze against walls for >2 seconds in close-quarters combat. Residual: ~8/100 Scout-vs-Scout seeds still produce ~0.8s wrong-direction arcs in dense combat. Visible-but-minor per Boltz judgment; judged acceptable for ship.

### Commit sequence on Slice B

1. **`761f0aa`** — Nutts-B original: geometry-gated wall-stuck detector + perpendicular-to-target fallback escape.
2. **Boltz round 1: HOLD.** Findings:
   - Unstick fired on 91/100 normal open-space matches — detector too aggressive; 10px-over-1.5s threshold tripped during routine close-quarters orbit.
   - `_wall_escape_direction`'s perpendicular-to-target fallback was the explicit moonwalk producer.
   - CI test glob `test_sprint13_*` missed all S14 tests.
   - `test_sprint11` moonwalk regressed from 4/100 baseline to 32/100.
3. **`1f6df8e`** — Lead-IC drift commit (see §4). ~40 min on determinism issues, got S11 moonwalk to 7/100.
4. HCD caught the role drift; directed hand-back to Nutts.
5. Lead reverted `1f6df8e` via force-push to `76d9030`, killed the in-flight Boltz re-review of lead-IC code, re-delegated to Nutts-B with investigation notes as **input**, not pre-baked solution.
6. **`4b344a9`** — Nutts-B fix-up:
   - Geometry gate added as the **first** check in `_check_and_handle_stuck` (early-out before any state writes when bot is in open space).
   - Removed perpendicular-to-target fallback from `_wall_escape_direction`; falls back to toward-target.
   - `UNSTICK_NUDGE_PX_PER_TICK` reduced 14 → 7.
   - CI test glob fixed: `test_sprint13_*` → `test_sprint1[0-9]_*.gd` + `test_sprint1[0-9].gd`.
   - T3 nav test retargeted from arena center (256,256) to wall (16,256) to match the new gate.
   - `test_sprint11` AC6 threshold widened from `==0` to `≤10/100` with explanatory comment.
7. **Boltz round 2: SHIP APPROVED.** Independently verified (stash + checkout main + rerun for flake claims). Test state at approval: S11 9/9 (8/100 moonwalk), S14.1 nav 5/5, S14.1 19/19, runner 72/72. Two non-blocking nits carried to S14.2.
8. HCD approved ship as-is 2026-04-16 ~21:50 EDT; nits folded into 14.2 housekeeping rather than churning merge. Squash-merged as `5f97cab`.

---

## 3. Process health — reviewer trilogy

### Gizmo (design)

**Utilization:** Informal. There is **no dedicated 14.1 design brief in `docs/design/`** on main. 14.1 scope came from the arc brief (`sprint14-arc-shape.md`) and a slice-level planning doc (`sprint14.1-loop-closure.md`), both of which existed only locally/uncommitted during the sprint.

**Gap:** Gizmo was not bootstrapped as a formal step in the orchestration loop for 14.1. For 14.2, Gizmo produced a formal brief (PR #75, merged as `f6b95b2`) — this is the correct pattern going forward. Treat 14.1 as the last sprint where Gizmo was optional.

### Boltz (review)

**Utilization:** High-value, two rounds.

- Round 1 caught a real bug — the 91/100 false-positive unstick fire rate — that would have shipped as a visible regression had reviewer been rubber-stamp.
- Round 2 verified the fix-up independently (instrumented probe, flake-baseline check via stash + main-checkout), not on the author's word.
- Surfaced two non-blocking nits with clear justification (threshold honesty, dead-red cleanup) rather than inflating them into blockers.

This is the reviewer pattern we want: block on real bugs, verify claims independently, defer cosmetic nits to the next sprint.

### Specc (audit)

**Utilization:** Not run until HCD flagged the gap at 2026-04-17 ~01:58 UTC. This audit closes that gap.

**Gap impact:** Sprint 14.2 planning began before Sprint 14.1 was audited. The carry-forward list was captured in `docs/plans/sprint14.2-carryforward.md`, which partially compensated, but the process-level lessons (role drift, Gizmo bootstrap gap, CI glob blind spot) were not written down until this document. Had playtest surfaced a 14.1 regression, there would have been no durable record of what was known at merge vs. what wasn't.

**Rule going forward:** Specc audit is a **hard gate** between sub-sprints. See §8.

---

## 4. Role-drift incident — lead-IC slip

_Written for a future lead who wasn't here._

### What happened

After Boltz's round-1 HOLD on Slice B, the studio lead (orchestrator) opened the repo and began debugging the unstick determinism issue directly. Committed `1f6df8e` as a fix attempt. Spent ~40 minutes on the investigation — tried `PackedVector2Array` vs typed `Array` for determinism, tightened proximity thresholds, got `test_sprint11` moonwalk from 32/100 (Boltz's round-1 regression) down to 7/100 (+3 over main's 4/100 baseline).

Secondary drift: the CI test-glob bug fix (`test_sprint13_*` → correct glob) was folded inline into the same lead-IC commit, rather than being separately delegated.

### HCD's correction

Verbatim gist: _"Role check: you're the studio lead, not an IC. You're currently debugging the unstick logic yourself — that's Nutts's job. Stop debugging. Hand it off."_

### Course correction executed

1. Killed the Boltz re-review that was already examining lead-IC code (to preserve review integrity — Boltz should not be reviewing the orchestrator's code).
2. `git reset --hard HEAD~1` on the PR branch, force-push back to Boltz HOLD state (`76d9030`).
3. Re-spawned Nutts-B with Boltz's findings **plus the lead's investigation notes as input** — explicitly not as a pre-baked solution. Nutts-B was free to pick a different path.
4. Nutts-B did in fact choose a different implementation path (threshold relaxation negotiation on `test_sprint11` AC6) that the lead had not considered while debugging.

### Rule established

> **If it touches source code in a slice branch, it is a Nutts commit.**
>
> Lead commits are limited to: docs, knowledge-base entries, orchestration artifacts (plans, audits), reverts, and merges.

### Why the rule matters — for the future lead reading this

The "I already have the repo open" heuristic is a **trap**. IC work feels cheap in the moment — you're unblocked, you know the code, the fix is right there. But three things break:

1. **Accountability blurs.** When a regression surfaces later, "who owned this fix" gets muddy. Slice commits need single authorship.
2. **Reviewer loop poisons.** Boltz cannot review lead-authored-as-Nutts code honestly. The orchestrator has context Boltz doesn't, and Boltz may defer where they'd otherwise block.
3. **Creative path preempts.** Nutts may have chosen a different (and in this case, better) approach. Lead-IC commits collapse the solution space before the IC even gets to look at the problem.

The "small fix" version of the trap — the CI test-glob inline fix — is equally real. Small fixes are still slice-branch commits; they go to Nutts. The determinant is *where the change lives*, not *how big it is*.

---

## 5. Technical residuals

Captured in `docs/plans/sprint14.2-carryforward.md`:

1. **Tighten `test_sprint11.gd` AC6 threshold** `≤10` → `≤9`. Boltz nit: a 25% headroom over observed 8/100 is overly loose; keep honest at observed+1. Non-blocking, low-risk.
2. **Clean up `test_sprint11_2` dead-red duplicate moonwalk assertion.** Pre-existing red that worsened from 4 → 8/100 as a side effect of S14.1. The assertion is a duplicate and contributes no signal; removing it is pure housekeeping.
3. **Optional: detector restructure — post-movement stuck eval, no per-tick state.** Would eliminate the residual ~0.8s wrong-direction arcs in dense Scout-vs-Scout combat by evaluating stuck state once per tick after all movement resolves, rather than interleaved with per-bot state writes. **Do not schedule yet.** Only pull forward if playtest surfaces the residual as visible. Tentatively S14.1-B2 if needed.

**Residual behavior summary:** ~8/100 Scout-vs-Scout seeds produce ~0.8s wrong-direction arcs in dense combat. Hard-bar regression tests (T1/T2/T4 in `test_sprint14_1_nav.gd`) for the actual wall-freeze bug hold. Boltz judged the residual visible-but-minor and acceptable for ship; HCD concurred.

---

## 6. Regression coverage assessment

Slice B's test shape is the right one for a feel-arc bug:

| Tier | Mechanism | Coverage |
|------|-----------|----------|
| **Hard-bar** (assertion must pass) | `test_sprint14_1_nav.gd` T1/T2/T4 | The actual playtest bug: walls, freeze >threshold, recovery direction. |
| **Soft-bar** (threshold) | `test_sprint11.gd` AC6 `≤10/100` | Downstream moonwalk behavior — non-zero is acceptable if bounded. |
| **Feel-bar** (human) | Playtest judgment | Wrong-direction arcs in dense Scout-vs-Scout. Acknowledged, not automated. |

### Assessment

**Right shape.** Hard-bar the bug you set out to fix. Soft-bar the downstream behavior that's harder to fully eliminate but must stay bounded. Acknowledge that some behavior lives in feel-bar territory and don't pretend a test can replace playtest judgment there.

### Recommendation for 14.2

Formalize this tiering as a studio convention: **every slice brief explicitly declares its hard/soft/feel tiering per acceptance criterion.** This forces the question "is this thing actually automatable, or am I pretending?" at plan time rather than discovering it mid-review. Specc should verify the tiering declaration exists as part of the audit gate.

---

## 7. CI / tooling — the glob bug lesson

### What happened

`.github/workflows/verify.yml` carried a test-discovery glob of `test_sprint13_*`. When S14 tests were added, the glob silently missed them. GitHub Actions CI was green on PR #74 even though **no S14 tests were running in CI at all**. Local runs caught the glob mismatch; CI did not.

### Why this is dangerous

CI green is load-bearing. If CI green can mean "no tests ran" rather than "tests ran and passed," the signal is worthless. The failure mode is silent — nothing errors, nothing warns, the PR just sails through.

### Fix applied in S14.1

Glob updated to `test_sprint1[0-9]_*.gd` + `test_sprint1[0-9].gd`. Covers S10–S19 without further edits.

### Lesson

Any new test-file prefix must be verified against `verify.yml` globs as part of the sprint's test-addition checklist.

### Recommendations

- **Short-term (S14.2):** Add a meta-test that asserts the glob matches the expected per-sprint test files — i.e., a CI-side sanity check that "files on disk matching `test_sprint*.gd`" equals "files the runner actually executed." If they diverge, fail.
- **Medium-term:** Shift to glob-agnostic discovery — e.g., `test_sprint*.gd` or discover-by-directory-walk. Removes the class of bug entirely.

---

## 8. Process gap closed — Specc audit as hard gate

### The gap

Specc audit was not run between Sprint 14.1 and Sprint 14.2 planning. HCD flagged this at 2026-04-17 ~01:58 UTC. This document is that closure.

### Rule going forward

**The Specc audit is a hard gate between sub-sprints. No N+1 planning or execution begins until sprint N's audit is committed to the repo.**

### Orchestration loop (canonical)

```
sub-sprint plan
    → Gizmo brief (formal, in docs/design/)
        → slice Nutts in parallel worktrees
            → Boltz review (block on real bugs, verify independently)
                → merge
                    → Specc audit (HARD GATE — committed to docs/audits/)
                        → next sub-sprint plan
```

### What "hard gate" means in practice

- The audit file (`docs/audits/sprintN.md`) must be committed to `main` before any Gizmo brief or Nutts slice for sprint N+1 is spawned.
- If playtest or HCD surfaces an issue with sprint N after merge but before the audit, the audit captures it. The audit is where the sprint *ends*, not the merge.
- The orchestrator is responsible for spawning Specc. If the lead is tempted to skip ("nothing interesting happened this sprint"), that is exactly when the audit is most valuable — because the lessons-that-didn't-land are the ones that silently calcify.

### What Specc audits should contain (minimum)

- What shipped, per slice, with player POV.
- Reviewer trilogy utilization — Gizmo, Boltz, Specc itself — with gaps called out by name.
- Any role-drift or process incidents, written for a future lead who wasn't present.
- Technical residuals with carry-forward pointers.
- Regression coverage shape per slice.
- CI/tooling lessons.
- Process rules established or changed this sprint.

---

## Appendix A — Key refs

- Merge commit: `5f97cab` (PR #74, squash)
- Slice B commit sequence: `761f0aa` → `1f6df8e` (reverted) → `76d9030` (HOLD state) → `4b344a9`
- Carry-forward: `docs/plans/sprint14.2-carryforward.md`
- 14.2 Gizmo brief: PR #75, merged as `f6b95b2`
- Test state at ship: S11 9/9 (8/100 moonwalk), S14.1 nav 5/5, S14.1 19/19, runner 72/72

## Appendix B — Carry-forward summary (one-line)

1. `test_sprint11.gd` AC6 threshold `≤10` → `≤9`
2. `test_sprint11_2` dead-red duplicate moonwalk assertion — remove
3. (Optional, conditional on playtest) Detector restructure: post-movement stuck eval, no per-tick state

---

_Audit complete. Gate cleared for Sprint 14.2._
