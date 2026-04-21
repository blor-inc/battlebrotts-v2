# Sprint 17.2 — Scout feel + wall-stuck bug triage

**PM:** Ett
**Status:** Planning (iteration 2 of S17)
**Sprint type:** Sub-sprint (combat-adjacent feel + bug triage)
**Parent arc:** [`sprints/sprint-17.md`](./sprint-17.md) — see §"S17.2 — Scout feel + wall-stuck bug triage"
**Gizmo design doc:** [`docs/design/s17.2-scout-feel.md`](../docs/design/s17.2-scout-feel.md) (landed via PR #178)

---

> ## 🛑 SCOPE GATE — READ FIRST
>
> **This sub-sprint is the single S17 carve-out that is allowed to touch `godot/combat/**`.** Arc brief §"SCOPE GATE" permits `combat/**` edits only for (a) scout-feel smoothing and (b) the wall-stuck bug root-cause / patch. All other sacred paths remain untouchable: `godot/data/**` (chassis/weapon/armor/module data), `godot/arena/**`, `docs/gdd.md`.
>
> Concrete allowances this sprint:
> - `combat_sim.gd` + `brott_state.gd` for velocity-vector smoothing, angular-velocity caps, and reversal damping (per Gizmo spec §4).
> - `combat_sim.gd` for the wall-stuck patch, once root-caused.
> - New tunable constants live in `combat_sim.gd`, NOT `chassis_data.gd` — keeps the `data/**` gate intact.
>
> Concrete prohibitions (restated):
> - No edits to Scout's `speed`, `accel`, `decel`, `turn_speed` in `chassis_data.gd`. Base numbers unchanged.
> - No edits to weapon/armor/module data.
> - No new chassis, no balance retunes, no GDD rewrites.
> - No pathfinding refactor as part of the wall-stuck patch — smallest safe change only. If wall-stuck root-causes to a pathfinding-wide problem, escalate to HCD and carry-forward.
>
> Full scope gate, sacred-paths list, and escalation triggers: [`sprints/sprint-17.md`](./sprint-17.md) §"🛑 SCOPE GATE", §"Sacred", §"Escalation triggers". Arc scope streak (S15.2 → S17.1): clean.

---

## Goal (condensed from arc brief §S17.2 + Gizmo spec)

Fix the two immersion-breaking movement complaints from the 2026-04-18 playtest:

1. **Scout feels like a mouse, not a brott.** Instantaneous direction flips on every TCR phase transition (TENSION → COMMIT → RECOVERY) violate the physical-inertia intuition that makes bots read as objects rather than particles. Gizmo's diagnosis: velocity is scalar-only; direction is re-derived every tick with zero angular-velocity model. Fix: a `_smooth_velocity` helper that rotates a real `b.velocity` vector at a chassis-specific `max_angular_velocity` cap, with brief reversal-damping on > 120° flips. Scout stays the fastest, highest-agility chassis — nimble, not magical.

2. **Bots occasionally get stuck next to walls.** Same playtest: "sometimes only to one bot — gets stuck on a wall and can't move." Possibly overlaps the separate "last 5 shots both bots stopped" complaint (single vs. mutual stuck). Root-cause investigation first, minimal patch second. Existing unstick infra lives at `_check_and_handle_stuck` / `UNSTICK_NUDGE_PX_PER_TICK` in `combat_sim.gd:630+` — Gizmo flagged this as the likely intersection point with scout-feel.

**S17.2 ships three tasks:** wall-stuck investigation, wall-stuck minimal patch, and the scout-feel smoothing pass. Order is enforced: wall-stuck before scout-feel, because the scout-feel helper needs a `bypass_smoothing` opt-out on whatever site the wall-stuck patch writes through (Gizmo spec §7).

---

## Tasks

S17.2 contains **3 tasks**, [S17.2-001]..[S17.2-003]. Confirmed task IDs match Gizmo's spec §11 Q1 assumption (numbering preserved; no renumber). Used verbatim in branches, PR titles, commit messages.

Per-task format: title + summary, playtest citation / source, acceptance criteria, scope notes, proposed complexity. Gizmo already shipped the scout-feel design doc; wall-stuck tasks still need a Gizmo investigation pass before Nutts builds.

**Dependency graph (enforced ordering):**

- [S17.2-001] Wall-stuck investigation → [S17.2-002] Wall-stuck patch → [S17.2-003] Scout-feel smoothing.
- [S17.2-001] and [S17.2-002] are sequential (investigation gates the patch shape).
- [S17.2-003] must not start until [S17.2-002] merges — scout-feel's unstick write-site opt-out flag depends on knowing where the unstick patch lands (Gizmo spec §7).

### [S17.2-001] Wall-stuck bug — root-cause investigation

- **Summary:** The 2026-04-18 playtest surfaced two related "bots stop moving" complaints. Gizmo investigates before any patch lands. Deliverable is a KB entry documenting the root cause, not a code change.
- **Citation — playtest (arc brief §S17.2 Citations):**
  > "occasionally bots stop moving... it's always next to a wall, i think they get stuck on walls? happened again, sometimes only to one bot - gets stuck on a wall and can't move"
  > "Toward the last 5 or so shots, both bots stopped moving and just shot at each other - is this a bug?"
- **Backlog issue:** None filed yet. Ett files a tracking issue (`bug: wall-stuck — investigation`) as the first step of this task so Gizmo has a linkable target. Existing issue [#122](https://github.com/brott-studio/battlebrotts-v2/issues/122) ("Post-movement stuck evaluation restructure") is related but not the same bug — #122 is a tick-ordering perturbation cleanup, not the visible stuck-on-wall complaint. Note this in the KB entry.
- **Acceptance criteria (concrete / testable):**
  - A KB entry lands at `docs/kb/s17.2-wall-stuck-rootcause.md` documenting: (a) reproduction steps (seed + scenario), (b) the traced code path that produces the stuck state, (c) whether the "last 5 shots both stopped" complaint shares root cause or is separate, (d) a recommended minimal patch shape with file + symbol targets.
  - Investigation must name the specific interaction — e.g., "unstick nudge direction is overwritten by separation push at `combat_sim.gd:NNN` before it applies" — not a vague "pathfinding is flaky."
  - If the root cause turns out to require a pathfinding refactor (out of scope), Gizmo escalates to Ett + HCD via the escalation-trigger channel rather than patching ad-hoc.
- **Scope notes — do NOT change:**
  - No code patches in this task. Investigation + KB doc only.
  - No data/** edits (walls are arena geometry — also sacred).
- **Expected files:** `docs/kb/s17.2-wall-stuck-rootcause.md` (new). Possibly `docs/design/s17.2-wall-stuck.md` if Gizmo wants a design-doc companion for the [S17.2-002] patch.
- **Proposed complexity:** **M** (investigation-driven; worst case an afternoon of trace-reading + repro).

### [S17.2-002] Wall-stuck bug — minimal patch

- **Summary:** Ship the smallest safe change identified by [S17.2-001]. Do NOT expand into a pathfinding refactor. If root-cause ends up requiring more than a ~50-line localized fix, Ett carry-forwards to a dedicated combat-arc sprint.
- **Source:** root-cause KB entry from [S17.2-001].
- **Dependency:** MUST NOT start until [S17.2-001] KB entry lands on main.
- **Acceptance criteria (concrete / testable):**
  - The repro scenario from the [S17.2-001] KB entry no longer reproduces the stuck state. Deterministic seed + tick-count evidence in the PR description.
  - Automated regression test added (`godot/tests/test_s17_2_wall_stuck.gd` or equivalent): loads the repro seed, simulates N ticks, asserts bot displacement exceeds threshold by tick T.
  - Full existing test suite passes. Zero test quarantining (hard arc-framework rule).
  - Replay-determinism preserved: fixed RNG → byte-identical JSON logs (same invariant as Gizmo spec AC-T2).
  - Diff stays inside `godot/combat/**` + new test file. Any spillover outside that envelope escalates to Ett.
- **Scope notes — do NOT change:**
  - No `godot/data/**` edits (wall geometry, chassis stats, etc.).
  - No pathfinding architecture changes. If the patch site touches `_check_and_handle_stuck` or `UNSTICK_NUDGE_PX_PER_TICK`, keep edits surgical — add a guard, reorder a write, fix a direction computation. No new subsystems.
  - No behavioral change to non-stuck bots. The patch must be invariant for bots that are moving normally.
- **Expected files:** `godot/combat/combat_sim.gd` (targeted patch); `godot/tests/test_s17_2_wall_stuck.gd` (new regression test); possibly `godot/combat/brott_state.gd` if a flag/field is needed on the state.
- **Proposed complexity:** **S–M** (depends on root cause; most likely S if it's a guard/ordering fix, M if it needs a new field on BrottState).

### [S17.2-003] Scout feel — velocity-vector smoothing + angular-velocity cap

- **Summary:** Implement the Gizmo spec `_smooth_velocity` helper (spec §4) and route all combat-movement position writes through it. Add real `b.velocity: Vector2` state + per-chassis `max_angular_velocity` (Scout 540°/s, Brawler 270°/s, Fortress 150°/s). Add reversal damping on > 120° flips. Scout `base_speed` / `accel` / `decel` unchanged.
- **Design doc:** [`docs/design/s17.2-scout-feel.md`](../docs/design/s17.2-scout-feel.md) — landed via PR #178. Nutts treats this doc as authoritative for constants, file list, and acceptance criteria.
- **Citation — playtest (arc brief §S17.2 + spec §1.1):**
  > "scout still feels a little bit too fast to follow... makes it feel like I'm watching mice run around rather than weighty brotts"
  > "the way scout moves is so crazy fast, ruins the robot feel"
  > "its movements are very jerky too"
- **Dependency:** MUST NOT start until [S17.2-002] merges — so the unstick write-site can be tagged `bypass_smoothing=true` (per Gizmo spec §7; this is the one place in the codebase that must NOT go through `_smooth_velocity`, or the unstick nudge will be rotationally damped back into the wall).
- **Acceptance criteria (concrete / testable):** Gizmo spec §8 is the source of truth. Summary:
  - **AC-1** Scout 180° reversal takes ≥ 3 ticks (300 ms), verifiable by per-tick `b.velocity.angle()` sampling.
  - **AC-2** Straight-line acceleration from stop unchanged (±1 tick vs. current build).
  - **AC-3** Pursuit still closes (Scout-vs-fleeing-Brawler tick-count regression ≤ +15%).
  - **AC-4** COMMIT → RECOVERY magnitude dip ≥ 35% for 2 ticks (reversal damping visible in logs).
  - **AC-5** No teleport: any 3-tick window satisfies |Δp| ≤ base_speed × 1.5 × 3 × TICK_DELTA + epsilon.
  - **AC-6** HCD subjective read in Optic visual diff: Scout reads as "brott" not "mouse."
  - **AC-T1** Unit test for `_smooth_velocity` angular cap.
  - **AC-T2** Replay-determinism preserved (byte-identical JSON logs under fixed RNG).
  - **AC-T3** Full existing suite passes; no test quarantining.
- **Scope notes — do NOT change:**
  - No `chassis_data.gd` rows. Scout speed/accel/decel/turn_speed unchanged. Angular-velocity caps live in `brott_state.gd::setup()` via `match chassis_type`, per spec §4.1 (explicit scope-gate preservation).
  - No GDD edits.
  - No change to Scout's agility archetype (it stays fastest + highest-accel + highest angular velocity).
  - Unstick nudge write-site bypasses `_smooth_velocity` (see dependency note above). If [S17.2-002] patches a different site, coordinate with Gizmo before flipping the flag default.
- **Expected files** (per spec §10):
  - `godot/combat/brott_state.gd` — activate `velocity` field, add `max_angular_velocity`, add `reversal_damping_timer`, set in `setup()`. ~15 LoC.
  - `godot/combat/combat_sim.gd` — add `_smooth_velocity` helper (~40 LoC), 4 new constants, replace ~15 call sites of `b.position += dir * spd`, add `bypass_smoothing` opt-out on the unstick path. ~90 LoC.
  - `godot/tests/test_s17_2_scout_feel.gd` — new unit test file for `_smooth_velocity`. ~60 LoC.
- **Proposed complexity:** **M** (touches hot movement loop, ~15 call-site migrations, but change is additive — one helper, callsite-by-callsite swap).

---

## Responses to Gizmo's open questions (spec §11)

Gizmo's design doc closed with 5 open questions for Ett. Decisions here are authoritative for this sub-sprint:

1. **Task numbering.** CONFIRMED as `[S17.2-003]` for scout-feel. Wall-stuck investigation is `[S17.2-001]`, wall-stuck patch is `[S17.2-002]`. IDs match arc-brief §S17.2 task sketch; no renumber.

2. **Ordering with wall-stuck.** CONFIRMED: scout-feel lands AFTER wall-stuck patch. Rationale per spec §7 — the unstick write-site must be tagged `bypass_smoothing=true`, and the exact site only becomes concrete once [S17.2-002] defines it. Dependency is enforced in the graph above and in the Pipeline flow section.

3. **Post-impl playtest drop.** KEEP IN S17.2, not S17.3. A 5-min HCD feel-check build is scheduled between [S17.2-003] Nutts impl and the S17.2 Specc audit. Small ask (five minutes for HCD, the build already has to be produced for Optic verify), high signal (the whole spec rests on HCD's "does this read as brott?" judgment). See §Playtest plan below. If HCD is unavailable at the scheduled window, we fall back to Optic visual-diff as the AC-6 proxy and flag the HCD spot-check as a carry-forward into S17.3 — but default plan is in-sprint.

4. **Brawler / Fortress scope.** EXTEND smoothing to all three chassis this sprint. Rationale: Gizmo's helper is chassis-generic, per-chassis caps are hand-tuned values in `brott_state.gd::setup()`, and the Brawler/Fortress caps (270°/s, 150°/s) are explicitly calibrated in spec §4.5 to not meaningfully change their typical-gameplay feel. Going Scout-only would mean two code paths (smoothed vs. legacy) in the hot loop — worse than one generic path. **Surface to HCD as a confirmable decision** (see §Open decisions for HCD) because it's a feel-touching call on two chassis that HCD didn't explicitly complain about. If HCD prefers Scout-only, Nutts gates the smoothing behind a per-chassis flag that defaults to on-for-Scout, trivially extensible later.

5. **Debug overlay.** CARRY-FORWARD to S17.3 (or backlog). Rationale: the overlay is a nice-to-have for tuning, but Gizmo spec §9 already lists the four tunable constants with sensible first-draft values, and the HCD feel-check build gives us a human-in-the-loop judgment call that doesn't require the overlay to be wired. Adding it in S17.2 inflates scope and risks churning `arena_renderer.gd` — a file that's not currently in the S17 envelope. Filed as carry-forward entry below.

---

## Carry-forwards from S17.1 — triage

Three items were flagged for S17.2 consideration coming out of S17.1:

- **Pre-existing `_lose_trick_item` ownership check** (Boltz note on S17.1-005 random-event popup). Status: the note was a defensive observation about pre-existing code, not a bug Boltz could reproduce, and S17.1-005 shipped without depending on a fix. **DROP from S17.2.** Would file as a backlog issue for a future gameplay arc — not in the S17 envelope (polish arc, not mechanics). If anyone encounters an actual ownership-mismatch bug in playtest, a bug issue gets filed and triaged against S17.3 or later.

- **"a Overclock" grammar nit.** Status: cosmetic string-formatting issue surfaced during S17.1 polish (article "a" vs. "an" before a vowel-sounding item name). **PUSH to S17.3.** Naturally fits the BrottBrain UI + card library curation scope — S17.3 already touches card strings during library curation, so a grammar helper (or proper "a/an" resolver) slots in there at no marginal cost. Out of scope for S17.2 which is combat/sim-focused.

- **Live-scene ESC e2e test.** Status: Optic noted during S17.1 verification that an end-to-end ESC-key test in a live-scene context was useful but not yet scripted. **PUSH to S17.3.** S17.3 is the UI-heavy sub-sprint (BrottBrain UX, drag, delete) where an ESC e2e fixture earns its keep on multiple tasks. Adding it here buys us nothing — S17.2 barely touches UI.

**Net:** zero carry-forwards kept in S17.2. All three either dropped or pushed to S17.3, consistent with S17.2's combat-adjacent-feel focus.

---

## Open decisions for HCD

Items requiring HCD confirmation before Nutts starts. None block [S17.2-001] (investigation-only); all block [S17.2-003] (scout-feel impl).

- **🟡 Brawler / Fortress smoothing scope.** Proposal: extend velocity-vector smoothing + angular-velocity caps to all three chassis this sprint (Scout 540°/s, Brawler 270°/s, Fortress 150°/s), per Gizmo spec §4.1. HCD complaint was Scout-specific, but the generic helper + calibrated caps are intended not to meaningfully change Brawler/Fortress feel. **Default to all-three** unless HCD prefers Scout-only (in which case Nutts adds a per-chassis gate flag).

- **🟡 5-minute HCD feel-check window.** Proposal: Nutts produces a playtest-ready build after [S17.2-003] impl, HCD spends ~5 minutes in-arena watching Scout (and Brawler/Fortress if the decision above is all-three) before Specc audit locks in acceptance. See §Playtest plan for the concrete handoff. HCD needs to confirm this window is available. If unavailable, fall back to Optic visual-diff for AC-6 and carry-forward HCD spot-check to S17.3.

- **🟢 Tuning values in spec §4.5.** Gizmo's first-draft constants (Scout 540°/s, reversal threshold 120°, damping factor 0.35, damping ticks 2) are explicitly labeled "first-draft educated values" in spec §9. HCD may want to tune during the feel-check. Values are exposed as top-of-file constants for trivial iteration. Not blocking — this is the tuning loop, not a decision gate.

---

## Playtest plan — 5-minute HCD feel-check

Scheduled between [S17.2-003] Nutts-impl-merge and Specc audit. **Not a full playtest session** — a focused feel-check answering one question.

**Handoff:**
- Nutts merges [S17.2-003], Optic produces the standard verify pass.
- Riv pings The Bott; The Bott surfaces the build link + a one-line ask to HCD: "5 minutes, one seeded match, does Scout read as brott or mouse?"
- HCD plays one seeded arena match (seed documented so the behavior is reproducible post-hoc).
- HCD responds with a yes / no / tune-these-constants-then-recheck call.

**Outcomes:**
- **Yes:** Specc audit proceeds on current values. S17.2 closes.
- **Tune:** Nutts adjusts the four tunable constants in `combat_sim.gd` (no code logic change), Optic re-verifies visual diff, HCD re-checks. One additional tuning round is plannable inside S17.2; a second round pushes to S17.3 as a dedicated tuning-only micro-task.
- **No (direction wrong):** Escalation to Ett + Gizmo. Possible carry-forward of the scout-feel pass if a redesign is needed. Low probability given the spec's alignment with HCD's verbatim framing, but named as a contingency.

**Fallback** (if HCD unavailable in window): Optic visual-diff stands in for AC-6. Nutts still produces the build; HCD spot-check carry-forwards into S17.3. Ett surfaces this outcome before closing the sub-sprint so HCD is not surprised.

No wider playtest scheduled this sub-sprint — wider playtest is an arc-end deliverable per `sprints/sprint-17.md` ("Playtest-ready drop at end of arc"). S17.2 feel-check is scout-specific.

---

## Pipeline flow (standard S17)

Per arc brief §"Pipeline flow":

**Gizmo designs task-by-task → Nutts builds → Boltz reviews → Optic verifies → Specc audits → Gizmo validates → Ett decides continuation.**

**Design status:**
- [S17.2-001] Gizmo investigation IS the design pass — KB entry is the deliverable, not a design doc.
- [S17.2-002] design emerges from [S17.2-001] KB entry; Gizmo may or may not write a companion design doc depending on patch complexity. If patch is trivial (a guard flip / ordering fix), Gizmo skips the design doc and goes straight to Nutts build.
- [S17.2-003] design is ALREADY DONE — `docs/design/s17.2-scout-feel.md` landed via PR #178. Nutts reads the spec and builds.

**Design-first task this sprint:** [S17.2-003] is the most design-inflected — and that design is already in hand. [S17.2-001] is investigation-first. [S17.2-002] is patch-minimal.

**Dependency-gated execution:** Riv does NOT spawn Nutts on [S17.2-002] until [S17.2-001] KB entry merges. Riv does NOT spawn anyone on [S17.2-003] until [S17.2-002] merges. Sequential by design — wall-stuck informs scout-feel's unstick-bypass flag location.

---

## Acceptance for S17.2 (from arc brief + this plan)

- Wall-stuck bug fixed OR root-cause documented + minimal patch landed + regression test added. "Quarantine with filed carry-forward issue" is acceptable fallback only if [S17.2-001] investigation reveals a root cause that requires out-of-scope pathfinding work — in which case Ett escalates and files the carry-forward.
- Scout movement reads as "brott" not "mouse" — HCD subjective read via 5-min feel-check build OR Optic visual-diff fallback.
- Zero diffs to `godot/data/**` across all S17.2 PRs.
- Zero diffs to `docs/gdd.md`.
- Full test suite passes; no tests quarantined or loosened.
- Replay-determinism preserved (byte-identical JSON logs under fixed RNG).

---

## Audit gate (HARD RULE)

Per `PIPELINE.md` sub-sprint close-out invariant (added by studio-framework PR #12):

**S17.2 is NOT closed until `audits/battlebrotts-v2/v2-sprint-17.2.md` lands on `studio-audits/main`.**

Specc produces the audit. Riv does not spawn Ett for S17.3 planning until the audit PR is merged on `studio-audits/main`. No shortcuts.

---

## Review / verify / audit assignments

| Task | Build | Review | Verify | Audit |
|---|---|---|---|---|
| S17.2-001 | Gizmo (investigation) | Ett (KB-doc review) | n/a (no code) | Specc (sub-sprint audit) |
| S17.2-002 | Nutts | Boltz | Optic | Specc |
| S17.2-003 | Nutts | Boltz | Optic (+ HCD feel-check) | Specc |

**Sprint audit:** Specc → `audits/battlebrotts-v2/v2-sprint-17.2.md` on `studio-audits/main`.

---

## Exit criteria

- [ ] [S17.2-001] Wall-stuck investigation KB entry merged to main (`docs/kb/s17.2-wall-stuck-rootcause.md`).
- [ ] [S17.2-002] Wall-stuck minimal patch merged; repro scenario no longer reproduces; regression test present.
- [ ] [S17.2-003] Scout-feel smoothing merged; all spec §8 ACs met; unstick path correctly bypasses `_smooth_velocity`.
- [ ] HCD 5-min feel-check completed OR Optic visual-diff fallback documented with HCD-spot-check carry-forward to S17.3.
- [ ] Optic verification doc: Scout reads as "brott" not "mouse" (visual diff) + no regressions in combat scenes.
- [ ] Scope-gate verification: zero diffs across all S17.2 PRs to `godot/data/**`, `godot/arena/**`, `docs/gdd.md`.
- [ ] Replay-determinism: fixed-seed JSON logs byte-identical to pre-change counterparts under a straight-line scenario (no phase flip) as sanity check; any intentional divergence on phase-flip scenarios documented.
- [ ] Specc audit `audits/battlebrotts-v2/v2-sprint-17.2.md` merged to `studio-audits/main`.

---

## Risks

- **Risk: wall-stuck root-causes to a pathfinding refactor.** If [S17.2-001] investigation finds the stuck state is a structural pathfinding problem (not a localized guard/ordering bug), the "minimal patch" framing breaks down.
  **Mitigation:** Investigation ACs require Gizmo to name a "recommended minimal patch shape." If no such shape exists, Gizmo escalates to Ett + HCD rather than inventing one. Carry-forward the wall-stuck fix to a dedicated combat-arc sprint; close [S17.2-002] as "quarantined with documented root cause," per arc-brief acceptance language.

- **Risk: scout-feel tuning requires more than one HCD feel-check round.** The spec's first-draft constants may not nail it.
  **Mitigation:** One additional tuning round is plannable in S17.2 (constants-only adjustment, Optic re-verify, HCD re-check). A second additional round pushes to S17.3 as a dedicated tuning micro-task. Named in §Playtest plan.

- **Risk: unstick write-site bypass flag gets mis-applied.** If [S17.2-002] patches a site that [S17.2-003] then forgets to mark `bypass_smoothing=true`, the unstick nudge gets rotationally damped back into the wall — worst-case regression.
  **Mitigation:** Dependency-ordering of [S17.2-002] before [S17.2-003] is hard-enforced. [S17.2-003] AC list explicitly includes "unstick path correctly bypasses `_smooth_velocity`." Boltz review on [S17.2-003] must verify the opt-out flag at the patched site. If [S17.2-002] doesn't patch an unstick site (root cause is elsewhere), [S17.2-003] still flags the existing `_check_and_handle_stuck` nudge with `bypass_smoothing=true` per spec §7.

- **Risk: Brawler / Fortress smoothing introduces subtle combat-sim perturbation.** Per-chassis angular caps change the effective direction-change time for two chassis HCD did not complain about. Could shift moonwalk counts, chase dynamics, stalemate frequency.
  **Mitigation:** AC-T2 (replay-determinism under fixed seed) + AC-T3 (full test suite passes, no quarantining) are hard blockers. If Brawler/Fortress smoothing breaks existing tests, fall back to Scout-only gated smoothing (per HCD-decision fallback above) and carry-forward Brawler/Fortress to S17.3 or later.

- **Risk: float-ordering nondeterminism from vector math.** Rotating velocity vectors introduces trig ops that could perturb tick-level reproducibility.
  **Mitigation:** Gizmo spec §10 "Landmines" section flags this. AC-T2 is the hard guard: byte-identical JSON logs under fixed RNG. Single-write-per-tick per bot (collapse multiple `b.position +=` into one accumulator) per spec §10 recommendation addresses this.

- **Risk: "last 5 shots both stopped" turns out to be separate from wall-stuck.** [S17.2-001] might reveal these are two bugs, not one.
  **Mitigation:** Investigation ACs explicitly require Gizmo to answer whether the two complaints share root cause. If they don't, the end-game disengagement complaint carries forward as a separate backlog issue; [S17.2-002] focuses on the single-bot wall-stuck case.

---

## Open questions / 🟡 surfaced

- **🟡 Wall-stuck patch shape unknown until [S17.2-001] lands.** [S17.2-002] complexity estimate (S–M) is provisional. Ett re-evaluates complexity after the investigation KB entry; may escalate to HCD if estimate balloons.

- **🟡 HCD feel-check window availability.** See §Open decisions for HCD — this is the primary HCD decision gating [S17.2-003]'s acceptance flow. Fallback plan documented.

- **🟢 Scope of "a Overclock" and live-scene ESC carry-forwards.** Both pushed to S17.3 per §Carry-forwards above. No decision needed this sprint; flagged for S17.3 planning.

---

## Carry-forward backlog (populated during sub-sprint)

Pre-populated from §Carry-forwards (S17.1) and §Responses (Gizmo Q5):

- **Debug overlay — dev-only velocity vector draw.** Gizmo spec §9 recommends; Ett decision: carry-forward to S17.3 or backlog. Would live in `arena_renderer.gd` behind a dev flag. ~S complexity.
- **"a Overclock" grammar nit.** Article "a/an" resolver for card / item strings. Fits S17.3 card-library curation.
- **Live-scene ESC e2e test.** Playwright fixture for ESC-key in live-scene context. Fits S17.3 UI work.
- **(Populated during sub-sprint)** — entries added by Ett / Riv as S17.2 surfaces non-scope findings.

---

## References

- Arc brief: [`sprints/sprint-17.md`](./sprint-17.md) §"S17.2 — Scout feel + wall-stuck bug triage", §"🛑 SCOPE GATE", §"Sacred", §"Escalation triggers".
- Precedent sub-sprint plan format: [`sprints/sprint-17.1.md`](./sprint-17.1.md).
- Gizmo scout-feel spec: [`docs/design/s17.2-scout-feel.md`](../docs/design/s17.2-scout-feel.md) — PR [#178](https://github.com/brott-studio/battlebrotts-v2/pull/178) (merged).
- Related (not same bug) backlog issue: [#122](https://github.com/brott-studio/battlebrotts-v2/issues/122) — post-movement stuck evaluation restructure. Cross-referenced in [S17.2-001] KB entry.
- Playtest source of truth: HCD-authored 2026-04-18 playtest notes, captured at workspace `memory/2026-04-20.md` §18:23 and transcribed in arc brief §S17.2 Citations.
- Framework: `studio-framework/PIPELINE.md` §"Sub-sprint close-out invariant" (hard audit gate).

---

**Plan authored by Ett, 2026-04-21. HOLD for HCD review before Riv spawns Gizmo on [S17.2-001]. Per task prompt: HCD explicitly wants a review pass on this plan before Nutts touches code.**
