# KB: Mirror-Only Test Coverage Hides Cross-Chassis Bugs

**Sprint:** 13.2
**Discovered by:** Optic (verification), Specc (pattern)
**Severity:** Medium
**Status:** Open

## Problem

Combat-mechanics sprints (S11.1 juke, S13.2 TCR) have repeatedly shipped with test suites composed entirely of symmetric / mirror matchups. The tests pass green, but the mechanic breaks as soon as Optic runs it with heterogeneous chassis. Two concrete examples from this project:

- **S11.1:** Juke movement worked when both bots had the same movement speed and engagement distance. Cross-chassis exposed a cap-bypass on the "away" juke.
- **S13.2:** TCR cycle completed normally in mirror sims (4.8 cycles / 20.7% hit rate for Fortress). Cross-chassis dropped to 1.3 cycles / 1.7% hit rate because different `ideal_distance` values caused bots to oscillate in/out of combat-movement range, resetting TCR state each time.

Mirror tests are cheap and easy to assert on. That's exactly why they're written first and, often, only.

## Root Cause

Mirror matchups are a symmetric fixed point of the combat system. Almost any timing, state-machine, or geometry bug that depends on *asymmetry* between the two bots is invisible to them. Specifically:

- Two bots with identical speeds never create differential timing windows.
- Two bots with identical `ideal_distance` values never oscillate in/out of each other's combat-movement range.
- Two bots with identical projectile speeds and hitbox sizes hit or miss in symmetric patterns — any leak of "fast projectile vs small hitbox" looks fine because both sides leak equally.

The bug is not in the mirror test. The bug is in the inference that "mirror green → mechanic correct."

## Pattern

**Any PR that introduces or modifies a combat-timing, state-machine, or projectile-geometry mechanic must include at least one cross-chassis integration test in the same PR.**

Concretely:
- Pair at least two chassis with materially different `movement_speed` and `ideal_distance`.
- Assert on an end-to-end metric (hit rate, match duration, state-cycle count), not just on "state transitions happen in order."
- If the metric depends on chassis parameters, assert a reasonable *range*, not a point value, so the test survives later balance tuning.

If that test can't be written easily, that's a signal the mechanic's coupling to chassis parameters isn't well understood yet — which is itself a sprint-relevant finding.

## Prevention

- PR template for `godot/combat/*` changes should have a check: "Cross-chassis integration test included? Which chassis pair?"
- Optic should treat "all tests are mirror" as an automatic request for additional sims before signing off.
- Boltz review should flag mirror-only test suites on combat-mechanics PRs as a quality concern, not just a completeness concern.
