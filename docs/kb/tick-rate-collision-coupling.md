# KB: Tick Rate × Projectile Speed Is an Implicit Collision Constraint

**Sprint:** 13.2
**Discovered by:** Optic (hit-rate collapse), Nutts (fix)
**Severity:** High
**Status:** Fixed in PR #56

## Problem

After S13.1 lowered the fixed tick rate from 20Hz to 10Hz, projectiles started passing through targets. Hit rates collapsed from the 20% range to 1.7% in cross-chassis matchups. The projectile code was unchanged; the bug surfaced purely because projectile step distance per tick doubled without a corresponding upgrade to the hit-detection geometry.

At 400 px/s with a 10Hz tick, projectiles move 40 px per tick. Target hitbox radius is 12 px. Point-vs-circle collision tested at the per-tick endpoint positions could skip entirely over the target between two consecutive ticks:

```
tick N:   projectile at (100, 100), target at (130, 100)  → not hit (distance 30 > 12)
tick N+1: projectile at (140, 100), target at (130, 100)  → not hit (distance 10 < 12 but already past)
```

Depending on exact timing, a 24 px diameter target had roughly a 60% chance of being skipped entirely by a 400 px/s projectile on a 10Hz tick.

## Root Cause

Per-tick point-vs-circle collision implicitly assumes `per_tick_travel < target_diameter`. The invariant was satisfied at 20Hz (20 px/tick vs 24 px diameter, mostly OK) and silently violated at 10Hz (40 px/tick vs 24 px diameter, frequently skips).

The S13.1 tick-rate change correctly re-derived all per-tick *movement* constants (regen rates, pathfinding cadence) but did not audit per-tick *collision* geometry.

## Pattern

**Any change to fixed timestep rate is an implicit change to every per-tick motion primitive.** When the timestep grows, any collision test that only samples endpoints becomes unreliable for fast-moving entities.

The general fix is swept collision: test the line segment from the previous position to the current position against the target, not just the endpoints. For projectile-vs-circle:

```
# closest point on segment AB to circle center C
AB = B - A
t = clamp(((C - A) dot AB) / AB.length_squared(), 0, 1)
closest = A + AB * t
hit = (closest - C).length() <= radius
```

Clamp projectile step distance to remaining range so projectiles don't overshoot their max range in a single tick either.

## Prevention

- **Any PR that changes `PHYSICS_FPS` / tick rate must include an explicit audit item:** "Per-tick travel distance of every moving entity (bots, projectiles, splash) vs smallest relevant hitbox radius. List each; confirm `travel_per_tick < 2 × smallest_radius` or use swept collision."
- Per-weapon projectile speeds should be declared explicitly on `WeaponData` (not hardcoded) so the audit above is a single-file review, not a code-wide search.
- End-to-end hit-rate assertions in sim tests catch this class of bug. Unit tests of individual collision calls do not.

## Related

- `docs/kb/mirror-only-test-coverage-gap.md` — why unit and mirror tests missed this despite the bug being severe.
