# S14.2 Slice B — AC8 chase-target tradeoff resolution

**Author:** Gizmo (design)
**Date:** 2026-04-17
**Context:** PR #77 (`sprint14.2-B-cards`, head `688a45e`) — Slice B aggression cards.
**Status:** Resolved. Non-blocking for PR #77 ship.

---

## Finding

Slice B's soft AC8 — "pit-bull Brawler beats vanilla Brawler ≥55/100 seeds" — measured **21/100** (pit_wins=21, draws=2, vanilla_wins=77) on the property test `_test_pit_bull_vs_vanilla_brawler`. The regression floor (≥10) holds, so the test passes; it is non-gating by design.

**Mechanic cause (Nutts-B's hypothesis, confirmed on read):** `CHASE_TARGET` sets `movement_override = "chase"`, which in `combat_sim._do_movement` takes a sibling branch to `"cover"`/`"center"` and bypasses the entire TCR (Target–Choose–Reposition) block, including `_enter_combat_movement` / `_do_combat_movement` orbit. In a **Brawler mirror** the trigger `WHEN_I_JUST_HIT_THEM (2s)` fires on the first successful trade — from that tick onward the pit-bull moves in a straight line toward an opponent who is still orbiting. Orbit dodges more bullets than pursuit eats. The pit-bull converts its dodge budget into commitment budget, and in a symmetric matchup commitment is the worse side of that trade.

This is design-level feedback, **not a sim bug**. CHASE is executing exactly as the brief (§3) specified: "move toward enemy at stance-max speed, ignoring normal stance-level kiting logic."

## Options considered

**(a) Scope CHASE to long-range only (code change).**
Add a range gate: if distance ≤ `max_weapon_range`, fall through to the default TCR branch (preserve orbit); only override when closing from beyond weapon range. Pros: makes CHASE strictly additive, likely lifts AC8 materially. Cons: (i) contradicts brief's explicit "ignoring normal stance-level kiting logic for this tick" — that language was intentional, chase is *commitment*, not "approach." (ii) Risks AC7 regression (the measured 6.90-tile close came from a Play-it-Safe chaser that would otherwise not close at all; a range gate that trips inside weapon range before contact is fine, but the test setup at ambush distance would need re-verification). (iii) Masks the design tension rather than naming it.

**(b) Reword AC8 to Brawler-vs-Scout rundown (AC change, no code).**
The brief's own §3 "Composition examples" lists **three** pit-bull-style builds, and the Brawler mirror is not one of them. The canonical aggression-card proof points are:
- *Pit bull (Brawler):* "once you draw blood, you don't let go" — a commitment ethos, not a mirror-dominance claim.
- *Lunge finisher (Fortress):* a defensive stance that lunges on low-HP trigger.
- *Rundown (Brawler vs Scout):* catch fleeing enemies.
AC8 as written asks whether commitment beats evasion in a symmetric trade — and the answer is "no, and that's fine." Rewording to a Scout matchup tests the thing CHASE was actually designed to do.

**(c) Accept the tradeoff (doc change only).**
Add a designer's note to the brief and/or the card's tooltip: pit-bull is a niche build, best vs runners and finishers, trades orbit for commitment. No AC change. Pros: zero code churn, names the tradeoff honestly. Cons: leaves AC8 on the books at 21/100 as a perpetual soft-fail — creates phantom "is this fixed yet?" tech debt in every future PR that touches this file.

**(d) — proposed — Combine (b) + (c) lite: reword AC8 + keep the mirror test as a tracked non-gating regression signal.**
Replace AC8's gating expectation with a Brawler-vs-Scout rundown scenario. Rename the existing mirror test to `_test_pit_bull_vs_vanilla_brawler_MIRROR_IS_NOT_DOMINANCE_DEMO` (or move to a `design_signals/` folder), keep the ≥10 floor to catch "CHASE stopped working entirely," but stop printing it as a soft-bar miss. Add one line to `sprint14.2-brottbrain-aggression.md` §3 documenting why the mirror is not the validation.

## Recommendation

**(d).** Concretely:

1. **AC change (primary).** AC8 new wording:
   > **AC8 (soft):** Brawler with "rundown" composition (`WHEN They're Running (4 tiles/sec) → CHASE_TARGET`) beats a Scout on an open map ≥55/100 seeds. This tests CHASE's design purpose — catching fleeing enemies — rather than mirror dominance.

2. **Test change.** Add `_test_rundown_brawler_vs_scout` as the new AC8 gate (soft ≥55, floor ≥10). Keep the existing `_test_pit_bull_vs_vanilla_brawler` but rename to `_test_pit_bull_vs_vanilla_brawler_tradeoff_signal`, drop the AC8 label, keep the ≥10 floor, log the result under a "design signal" print header.

3. **Doc change.** Append one paragraph to `sprint14.2-brottbrain-aggression.md` §3 under "Composition examples" clarifying that pit-bull is a commitment build and mirror-matchup dominance was never its design intent.

4. **Code change.** **None.** Option (a)'s range-gated chase is a legitimate S14.3+ exploration (see "Deferred" below), not a correction to PR #77.

### Why this over (a)

HCD's stated pain is "I can't build an aggressive brott." The fix that matters is: **can a player author a composition that expresses aggression and see it win where aggression is supposed to win?** Rundown says yes. Mirror says no. We should measure the thing the brief promised, not punish CHASE for not being a universal upgrade.

Option (a) is also a non-trivial refactor of the movement override model — chase currently is symmetric with cover/center as a *mode*, and collapsing it into a conditional approach-assist blurs that model. If we want CHASE to compose with orbit, the better path is a *separate* "close-and-orbit" action (e.g. `CLOSE_TO_RANGE`) in S14.3, not a mutation of CHASE's semantics mid-sprint.

### Why this over (c)

Plain "accept it" leaves a 21/100 soft-fail on the ledger. Every future dev reading the PR will wonder if it's still broken. Rewording is the honest fix.

## Implementation

- **Owner:** Nutts-B follow-up PR (small, test + doc only; ~30 min).
- **Files:** `godot/tests/test_sprint14_2_cards.gd` (rename existing test, add new rundown test), `docs/design/sprint14.2-brottbrain-aggression.md` (§3 paragraph + AC8 rewording).
- **Rundown scenario spec:** open map, Scout at (12,8) with default-for-chassis brain (which includes the hit-and-run card set), Brawler at (4,8) with `default_for_chassis(1) + WHEN_THEYRE_RUNNING(4) → CHASE_TARGET`. 1000 ticks, count Brawler kills.
- **Expected outcome:** ≥55/100 based on AC7's measured 6.90-tile close in 30 ticks — over a full match the Brawler should overtake a fleeing Scout reliably. If rundown *also* sub-50s, that's a real problem and escalates back to option (a).

## Blocking?

**Non-blocking.** PR #77 ships as-is. The AC8 miss is cosmetic at the test level (test passes at the ≥10 floor), and the resolution is an AC + test rewrite, not a behavior change. Nutts-B's follow-up PR can land after #77 merges or in early S14.3 — lead's call on routing. PR comment on #77 will note this so Boltz's merge review doesn't treat the soft-bar miss as unresolved.

## Deferred (S14.3+ exploration, not committed)

A `CLOSE_TO_RANGE` action that closes distance then hands back to TCR orbit is an interesting separate card — it occupies the design space option (a) gestures at, without mutating CHASE's commitment semantics. Not proposing it for the S14.3 brief; flagging here for the card library roadmap conversation.
