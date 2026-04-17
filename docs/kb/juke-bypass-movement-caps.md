# KB: Juke/Burst Movement Can Bypass Movement Caps

**Sprint:** 11.1 (discovered), 15 (follow-up: juke branch gone, new bypass sources found)  
**Discovered by:** Optic (verification), Specc (root cause)  
**Severity:** Low  
**Status:** Partially mitigated (S15 per-path clamps); root-cause Option 2 refactor still deferred

## Update — Sprint 15 (2026-04-17)

The original `juke_type == "away"` branch **no longer exists** in `combat_sim.gd` (`git grep 'juke'` in `godot/combat/combat_sim.gd` is empty; only vestigial `BrottState.juke_type` state remains). The `backup_distance` budget is now respected everywhere inside `_do_combat_movement()`.

However, `test_sprint11_2.gd::test_away_juke_cap_across_seeds` still fails on `main` (8/100 violations on Scout vs Scout close-quarters). Investigation (PR #80, Nutts + Boltz) found **two new unclamped bypass paths** matching the exact same anti-pattern:

1. **Bot-bot separation force** in `_move_brott` (~L535): `b.position += sep.normalized() * repulsion_speed` — when `sep` is anti-parallel to `to_target`, this is unclamped backward movement at up to 11.5 px/tick.
2. **Unstick nudge** in `_check_and_handle_stuck` (~L613): `b.position += nudge * UNSTICK_NUDGE_PX_PER_TICK` — `_wall_escape_direction` can resolve to a backward vector away from target when no clear wall/pillar signal exists, at 7 px/tick for 8 ticks.

PR #80 applies per-path clamps to both (gating the backward component against the shared `backup_distance` budget, passing lateral/forward through untouched). This closes the two bypass paths Ett scoped without a refactor.

**Remaining failure mode (not fixed by S15):** the test metric `movement.normalized().dot(to_target.normalized()) < -0.7` uses *post-tick* `to_target`. When two bots both COMMIT toward each other at close range, they can swap positions in a single tick — and forward COMMIT push then reads as "backward" in the new post-tick frame. This produces test-metric-registered backward runs of 40–100+ px even though no path retreats in its own reference frame. Reaching `violations == 0` requires either (a) preventing bot-to-bot crossover during COMMIT (a movement-pipeline change) or (b) Option 2 below (post-processing clamp at the tick boundary). Both are refactors; deferred to a follow-up sprint.

**Don't re-chase the juke branch — it's gone. Future moonwalk bugs live in: separation force, unstick nudge, and COMMIT-crossover geometry.**

## Problem

Movement caps (like the moonwalk/backup cap of 1 tile) are enforced in the normal movement path but not in burst/juke movement paths. The "away" juke in `_do_combat_movement()` moves the bot backward without checking `backup_distance`, bypassing the 1-tile moonwalk cap.

## Root Cause

The moonwalk cap is implemented as a per-tick check in the normal orbit/engagement section:
```gdscript
if b.backup_distance < TILE_SIZE:
    var step = minf(base_spd, TILE_SIZE - b.backup_distance)
    ...
```

But the juke system has its own movement branch that doesn't share this budget:
```gdscript
"away":
    b.position -= to_target.normalized() * juke_spd  # No cap check!
```

## Pattern

**Any time you add a movement cap or constraint, verify ALL movement paths respect it** — not just the primary one. Movement systems tend to accumulate multiple paths (normal, juke, dash, knockback, separation force) and constraints added to one path are easily missed in others.

## Fix

Either:
1. Track `backup_distance` in the juke "away" branch and clamp against remaining budget
2. Apply movement caps as a post-processing step after all movement is calculated (single enforcement point)

Option 2 is more robust long-term — single enforcement point means future movement paths automatically respect existing caps.

## Lesson

**Prefer post-processing enforcement over per-path enforcement.** Movement constraints applied at the end of the movement pipeline (after all sources are summed) can't be bypassed by new movement sources added later.
