# Sprint 17.3 — BrottBrain UI + card library curation

**PM:** Ett
**Status:** Planning (iteration 3 of S17 — BrottBrain UI + card library)
**Sprint type:** Sub-sprint (UI bug-fix + content curation)
**Parent arc:** [`sprints/sprint-17.md`](./sprint-17.md) — see §"S17.3 — BrottBrain UI + card library curation"
**Design input:** Gizmo S17.3 design spec (2026-04-21) — arc-intent verdict `progressing`; roster diff, per-task specs, and scope-gate sign-off embedded below (§6, §"Card-library roster diff (Gizmo canon)").

---

## SCOPE GATE — READ FIRST

This sub-sprint is a **UI bug-fix + content curation** slice. Scope-gate state from the arc brief is unchanged, with one narrow pre-approved exception for CHASE_TARGET wiring:

- No balance changes to `godot/data/**` (`chassis_data.gd`, `weapon_data.gd`, `armor_data.gd`, etc.).
- No edits to `docs/gdd.md`. Three drift items (GDD-DRIFT-1/2/3) plus four new card rows are filed as post-arc carry-forward in §"GDD carry-forward" — do NOT edit `docs/gdd.md` mid-arc.
- No changes to `godot/arena/**`.
- `godot/combat/**` is **scope-exception territory for S17.3-004 only**:
  - CHASE_TARGET needs a minimal additive `movement_override = "chase"` branch in `combat_sim.gd`. Gizmo signed off (S17.3 design spec §6). This is consistent with the S14.2-approved scope — CHASE was approved there, implementation just didn't ship.
  - WHEN_THEYRE_RUNNING and WHEN_I_JUST_HIT_THEM trigger wiring (additive) — also pre-approved under S14.2 canon.
  - No behavior change to non-CHASE paths. No refactors. No "while we're here" rewrites.
- `godot/tests/**` is additive-only (new card-library roster tests).
- Playtest-ready drop at end of arc is on the line. Hold the streak: clean scope-gate across S15.2 → S16.1 → S16.2 → S16.3 → S17.1 → S17.2. S17.3 makes it six.

Full gate/sacred-paths/escalation reference: `sprints/sprint-17.md` §"SCOPE GATE", §"Sacred", §"Explicitly out of scope", §"Escalation triggers".

---

## Goal (condensed from arc brief §S17.3 + Gizmo design spec)

Ship BrottBrain "recognizably fun" per HCD's fifth arc-acceptance bullet. Fix the three things the 2026-04-18 playtest called out:

1. **Drag lies.** UI claims "drag to reorder" + "+ Drag a card here" but has zero Control.gui_input / drag handlers. Click-to-add works. Remove the lie; defer real drag to a future polish arc.
2. **Delete is unintuitive.** Bare `✕`, no color, no tooltip. Red-tint + tooltip, no confirm dialog.
3. **Library is noisy AND missing CHASE/CHARGE.** Hide WHEN_CLOCK_SAYS + GET_TO_COVER (both zero-composition-value per playtest + code comments); reword WHEN_LOW_ENERGY label to match S17.1-004 energy-bar copy; add CHASE_TARGET (CHARGE folded per S14.2 §3), FOCUS_WEAKEST, WHEN_THEYRE_RUNNING, WHEN_I_JUST_HIT_THEM.

Also: cherry-pick the shippable content from the closed-unmerged PR #77 (CHASE triggers + tests, 29/29 green pre-closure) onto current main rather than reviving the stale branch.

**Arc acceptance bar for S17.3 (from arc brief §S17.3 acceptance + HCD 5th bullet):**
- Drag text/docs no longer lie — click-to-add is the honest UX (real drag carry-forward).
- Delete interaction is 1-click-from-obvious (red tint + tooltip).
- Card library curated per Gizmo roster diff (hide 2, reword 1, add 4). Selected-row accent-tint fix folded in.
- PRs #76/#77 decisively resolved — already closed unmerged by `brotatotes` 2026-04-20; shippable PR #77 content cherry-picked into S17.3-004.
- Playtest-ready drop.

---

## Task list

S17.3 contains **4 mandatory tasks + 1 optional stretch**. PR #77 cherry-pick is folded into S17.3-004 (combined with card-library curation); PR #76 polish is folded into S17.3-002/S17.3-003 (drag + delete). S17.3-001 is therefore re-scoped to a short carry-forward closure task (documenting the #76/#77 folds) rather than triage.

| ID | Title | Complexity | Dependencies | AC count |
|---|---|---|---|---|
| S17.3-001 | Closed-PR carry-forward documentation (#76 + #77) | S | none | 2 |
| S17.3-002 | Fix drag behavior — remove the lie (option A) | S | none | 3 |
| S17.3-003 | Delete interaction redesign — red tint + tooltip | S | none | 3 |
| S17.3-004 | Card-library curation + selected-row fix + PR #77 cherry-pick + CHASE wiring | L | 001 (doc), parallel-safe with 002/003 | 8 |
| S17.3-005 | (Stretch) End-to-end BrottBrain flow polish | M | 002, 003, 004 | — |

Task sizing note: S17.3-004 is the large task by a wide margin (touches `godot/brain/brottbrain.gd`, `godot/ui/brottbrain_screen.gd`, `godot/combat/combat_sim.gd`, new tests, plus cherry-pick from PR #77). 002 and 003 are 30min – 1hr Nutts tasks each.

---

## Card-library roster diff (Gizmo canon — Nutts implements verbatim)

**This section is design canon.** Nutts does not re-design the roster. If implementation surfaces an issue with any entry, stop and bounce back to Gizmo via Riv.

Convention per Gizmo spec §4:
- **Hide** = remove from `TRIGGER_DISPLAY` / `ACTION_DISPLAY` dicts in `brottbrain_screen.gd`. Keep enum in `brottbrain.gd` (save-compat).
- **Reword** = change label text in display dict. Enum untouched.
- **Add** = new enum value (append to end for save-compat) + new display entry + sim wiring.

### Triggers (10 → 11)

| Enum | Label | Verdict | Rationale |
|---|---|---|---|
| WHEN_IM_HURT | 💔 When I'm Hurt | KEEP | Core defensive. |
| WHEN_IM_HEALTHY | 💪 When I'm Healthy | KEEP | Inverse. |
| WHEN_LOW_ENERGY | 🔋 When I'm Low on Energy | **REWORD** (was "Low on Juice") | Matches S17.1-004 energy-bar copy; playtest: "i'm confused what the blue bar is." |
| WHEN_CHARGED_UP | ⚡ When I'm Charged Up | KEEP | |
| WHEN_THEYRE_HURT | 💔 When They're Hurt | KEEP | Core offensive. |
| WHEN_THEYRE_CLOSE | 📏 When They're Close | KEEP | Spatial. |
| WHEN_THEYRE_FAR | 📏 When They're Far | KEEP | Inverse. |
| WHEN_THEYRE_IN_COVER | 🧱 When They're In Cover | KEEP | Grounded. |
| WHEN_GADGET_READY | ✅ When Gadget Is Ready | KEEP | Module timing. |
| WHEN_CLOCK_SAYS | ⏱️ When the Clock Says | **HIDE** (tray-hide, enum-keep) | HCD playtest 2026-04-18: "a lot of things i didnt really want like clock time." Zero composition value in 13.x–17.x. Save-compat preserved. |
| **NEW** WHEN_THEYRE_RUNNING | 🏃 When They're Running | **ADD** | CHASE triggering fantasy. Param: int tiles/sec, default 4. Semantics per S14.2 design doc §3: enemy vel mag ÷32 ≥ threshold AND dot(enemy_vel, enemy→brott) < 0. Proven in PR #77 (29/29 tests green). |
| **NEW** WHEN_I_JUST_HIT_THEM | 🎯 When I Just Hit Them | **ADD** | Pit-bull/commitment fantasy. Param: int seconds grace, default 2. Requires `last_hit_time_sec` on BrottState (in PR #77). |

### Actions (6 → 7)

| Enum | Label | Verdict | Rationale |
|---|---|---|---|
| SWITCH_STANCE | 🔄 Switch Stance | KEEP | Core. |
| USE_GADGET | 🔧 Use Gadget | KEEP | Core. |
| PICK_TARGET | 🎯 Pick a Target | KEEP | Core. |
| WEAPONS | 🔫 Weapons | KEEP | Core. |
| GET_TO_COVER | 🧱 Get to Cover | **HIDE** (tray-hide, enum-keep) | `brottbrain.gd:25` says "not fully implemented" since Sprint 4. Nobody composes around a broken card. Issue #116 stays open as carry-forward. |
| HOLD_CENTER | 📍 Hold the Center | KEEP | |
| **NEW** CHASE_TARGET | 🏃 Chase Them | **ADD** | HCD playtest: "didn't have some things i wanted like charge or chase after." Sets `movement_override = "chase"`; `combat_sim.gd` branches. **CHARGE folded into CHASE** per S14.2 §3 ("functionally identical to CHASE_TARGET for first 1–2 seconds"). |
| **NEW** FOCUS_WEAKEST | 🎯 Focus the Weakest | **ADD** | Sugar for PICK_TARGET(weakest). In PR #77 already. |

**CHASE vs GET_TO_COVER vs #116:** CHASE is NEW. Both stay in enum. GET_TO_COVER stays hidden. Issue #116 remains open as carry-forward (do not close).

**Roster-count check (from Gizmo):** 11 triggers (2 rows @ ~700px wrap, 115px wide) and 7 actions (2 rows, 125px wide) both fit. Nutts must verify no tray+card-list overlap at 8 placed cards per AC4 of S14.2.

---

## Task specs

### S17.3-001 — Closed-PR carry-forward documentation

**Rationale for re-scope:** PRs #76 and #77 were closed unmerged on 2026-04-20 by `brotatotes` with comment "If the work is still wanted, the right path is to reopen via a new sprint." Both had ✅ SHIP verdicts from Boltz pre-closure (#76: 30/30 green; #77: 29/29 green). There is nothing to triage — HCD's intent is explicit: reopen via new work. Therefore:

- **PR #77 shippable content** (CHASE_TARGET, WHEN_THEYRE_RUNNING, WHEN_I_JUST_HIT_THEM, FOCUS_WEAKEST, `last_hit_time_sec` on BrottState, 29 associated tests) → cherry-pick into S17.3-004.
- **PR #76 content** (BrottBrain UI polish single-file edit) → fold into S17.3-002 (drag lie) and S17.3-003 (delete redesign) as applicable. Nutts reads #76's diff and pulls only the parts that match 002/003 specs.

**Task deliverable (S17.3-001):** A short KB note at `docs/kb/s17.3-closed-pr-carry-forward.md` documenting which S17.3 tasks subsume which parts of #76/#77, so the audit trail is clean. No code changes.

**Acceptance:**
- [ ] `docs/kb/s17.3-closed-pr-carry-forward.md` committed, linking #76 and #77 and mapping each PR's content to the S17.3 task that absorbs it.
- [ ] GitHub issues #76 and #77 remain closed; no reopen.

**Agent:** Nutts (or Riv delegate — this is a doc task, low risk).

---

### S17.3-002 — Fix drag behavior (option A: remove the lie)

**Diagnosis (per Gizmo spec §5):** `brottbrain_screen.gd` has a doc-comment claim "drag-to-reorder" and empty-slot text "+ Drag a card here" but **zero `Control.gui_input` / drag-start / drop handlers.** Playtest "It says drag but I can't drag" is literally true. UI lies.

**Gizmo decision: option A (remove the lie), not option B (implement real drag).** Real drag is a full design exercise for a future arc (animation, hit testing, undo-on-invalid-drop). Ship the honest click-to-add UX now; carry-forward issue files real drag.

**Scope:**
- Remove the "drag-to-reorder" doc-comment in `brottbrain_screen.gd`.
- Change empty-slot text from "+ Drag a card here" to something that reflects click-to-add (suggest "+ Tap to add card" or Gizmo-blessed wording — Nutts picks; Gizmo review gate catches any drift).
- No other behavior changes.

**Acceptance:**
- [ ] Doc-comment claim "drag-to-reorder" is removed from `brottbrain_screen.gd`.
- [ ] Empty-slot prompt text no longer uses the word "drag" (click/tap copy instead).
- [ ] New issue filed in `brott-studio/battlebrotts-v2` with `label:backlog` titled "Implement real drag-to-reorder in BrottBrain UI (S17.3 carry-forward)" — referencing this plan and option B from Gizmo spec §5.

**Agent:** Nutts. ~30min.

---

### S17.3-003 — Delete interaction redesign

**Current state (per Gizmo spec §5):** Bare `✕` button, no color, no confirmation, click→gone. Playtest: "delete button was very unintuitive."

**Spec (minimal per ux-vision.md pillars):**
- Red tint: button modulate `Color(1.0, 0.4, 0.4)` (readable on white panel; "intentional color" pillar).
- Hover state: full red `Color(1.0, 0.2, 0.2)` + cursor pointer.
- Tooltip: `"Delete this card"` (text-only, no hotkey copy).
- **No confirm dialog.** Undo-via-re-add is cheaper; BrottBrain edits are non-destructive to runtime state.

**Out of scope:** animation on delete, undo history, multi-select-delete.

**Acceptance:**
- [ ] Delete button modulate color is `Color(1.0, 0.4, 0.4)` at rest and `Color(1.0, 0.2, 0.2)` on hover.
- [ ] Cursor is a pointer on hover.
- [ ] Tooltip "Delete this card" is visible on hover (no hotkey text).

**Agent:** Nutts. ~30min–1hr.

---

### S17.3-004 — Card-library curation + selected-row fix + PR #77 cherry-pick + CHASE wiring

**This is the large task.** Implements §"Card-library roster diff" verbatim, cherry-picks PR #77 shippable content, wires CHASE_TARGET in `combat_sim.gd` per Gizmo's pre-approved scope exception, and fixes the invisible selected-row overlay.

**File touches (Nutts):**
- `godot/brain/brottbrain.gd`:
  - Append new enum values: `WHEN_THEYRE_RUNNING`, `WHEN_I_JUST_HIT_THEM`, `CHASE_TARGET`, `FOCUS_WEAKEST`. **Append to end of enum for save-compat.**
  - Add `last_hit_time_sec` to BrottState (from PR #77).
- `godot/ui/brottbrain_screen.gd`:
  - Update `TRIGGER_DISPLAY` / `ACTION_DISPLAY` dicts per §"Card-library roster diff":
    - Reword WHEN_LOW_ENERGY label "When I'm Low on Juice" → "When I'm Low on Energy".
    - Hide (remove display entries for) WHEN_CLOCK_SAYS and GET_TO_COVER.
    - Add display entries for WHEN_THEYRE_RUNNING, WHEN_I_JUST_HIT_THEM, CHASE_TARGET, FOCUS_WEAKEST.
  - Fix selected-row overlay: currently α=0.01 (invisible). Set to `Color(0.3, 0.6, 1.0, 0.3)` (blue, 30% alpha) per Gizmo spec §5.
  - Verify tray + card-list non-overlap at 8 placed cards (AC4 of S14.2).
- `godot/combat/combat_sim.gd` (pre-approved additive scope):
  - Wire CHASE_TARGET: sets `movement_override = "chase"`; add minimal additive branch. No behavior change to non-CHASE paths.
  - Wire FOCUS_WEAKEST: sugar for existing weakest-target logic.
  - Wire WHEN_THEYRE_RUNNING trigger evaluator (semantics per S14.2 §3: enemy vel mag ÷32 ≥ threshold AND dot(enemy_vel, enemy→brott) < 0).
  - Wire WHEN_I_JUST_HIT_THEM trigger evaluator (uses `last_hit_time_sec` from BrottState, default grace 2s).
- `godot/tests/**` (additive only):
  - Card-library roster tests: assert display-dict counts (11 triggers, 7 actions), assert hidden enums still exist (save-compat), assert new enums are in display dicts.
  - Cherry-pick PR #77's 29 tests where they still apply on current main.

**Cherry-pick strategy (PR #77):** Nutts rebases PR #77's commits onto current main (PR #77 branch still exists on GitHub even though PR is closed), resolves conflicts, and pulls the work into a fresh branch for S17.3-004. Do NOT reopen PR #77. File a new PR.

**Acceptance:**
- [ ] `godot/brain/brottbrain.gd` contains new enum values appended at end (no reordering — save-compat).
- [ ] `brottbrain_screen.gd` display dicts match §"Card-library roster diff" exactly (11 triggers shown, 7 actions shown).
- [ ] WHEN_CLOCK_SAYS and GET_TO_COVER enums still exist (loaded save files with those cards still parse).
- [ ] Selected-row overlay is visibly tinted blue at 30% alpha.
- [ ] `combat_sim.gd` CHASE_TARGET branch is additive — non-CHASE paths are byte-identical (Boltz verifies via diff).
- [ ] WHEN_THEYRE_RUNNING semantics match S14.2 §3 (threshold + approach-direction dot-product).
- [ ] WHEN_I_JUST_HIT_THEM uses `last_hit_time_sec` with 2s default grace.
- [ ] All existing tests still pass; new card-library tests added and green.
- [ ] Tray + card-list visually non-overlapping at 8 placed cards (verified by Optic or screenshot).

**Agent:** Nutts build; Gizmo design-review checkpoint before Boltz (roster diff must match canon exactly); Boltz review; Optic verify (screenshot of tray at full roster + 8 placed cards). Issue #116 remains open — do not close.

---

### S17.3-005 — (Stretch) End-to-end BrottBrain flow polish

**Deferrable per arc brief "if time."** Gizmo's read: 001–004 is already a full sprint. **Ett's call: treat 005 as stretch; cut if sizing pressures emerge.** If 002/003/004 land cleanly with time remaining, Riv may spawn this; otherwise carry-forward.

**If taken:**
- Tighten click-to-add → feedback loop (no new features; speed/polish on existing flow).
- No new cards, no new mechanics.

**Acceptance:** Gizmo-defined at the point of pickup; not pre-specified here.

**Agent:** Nutts if taken. Otherwise carry-forward issue.

---

## Sacred (unchanged from arc brief)

- `godot/data/**` — untouched. No balance changes.
- `docs/gdd.md` — untouched. GDD drift filed as carry-forward (see §"GDD carry-forward" below).
- `godot/arena/**` — untouched.
- `godot/combat/**` — S17.3-004 has a narrow pre-approved additive scope for CHASE_TARGET + WHEN_THEYRE_RUNNING + WHEN_I_JUST_HIT_THEM wiring per Gizmo §6. No other changes.
- Test suite assertions that currently pass — no loosening.
- Issue #116 (GET_TO_COVER) — stays open as carry-forward. Do not close.

---

## Explicitly out of scope for S17.3

- Real drag-to-reorder implementation (option B in Gizmo §5) — filed as carry-forward issue in S17.3-002.
- BrottBrain screen redesign — only bug fixes and content curation in this sub-sprint.
- GET_TO_COVER re-implementation — issue #116 remains open as carry-forward.
- Animation on delete, undo history, multi-select delete.
- Any `godot/data/**` edit.
- Any `docs/gdd.md` edit — see GDD carry-forward below.
- Balance or number tuning.
- Art swaps, audio work.

Anything proposed mid-sprint that matches the above: carry-forward issue filed, NOT executed.

---

## GDD carry-forward (post-arc reconciliation)

Per Gizmo spec §2 — do NOT edit `docs/gdd.md` during S17.3. File as carry-forward. Append to `sprints/sprint-17.md` §"Carry-forward backlog" at arc close:

| # | GDD location | Current text | Post-S17.3 reality | Recommendation |
|---|---|---|---|---|
| GDD-DRIFT-1 | §1 "Core Loop" line 12; §4.1 lines 91, 129 | "drag-and-drop Behavior Cards" | Click-to-add (real drag = future arc) | Update to "click-to-build" OR implement real drag in a later arc. |
| GDD-DRIFT-2 | §4.2 Trigger Cards table (line 116) | Lists "When the Clock Says" as shippable | S17.3 hides WHEN_CLOCK_SAYS (enum kept for save-compat) | Remove row in post-arc GDD pass. |
| GDD-DRIFT-3 | §4.2 Action Cards table (line 126); §4.2 example #5 (line 166) | Lists "Get to Cover" as shippable; example uses WHEN_CLOCK_SAYS | S17.3 hides GET_TO_COVER (flagged "not fully implemented" since Sprint 4) | Remove row; rewrite example #5 with a shipped trigger. |
| GDD-ADD-1 | §4.2 tables | (no entries) | Ship CHASE_TARGET, FOCUS_WEAKEST, WHEN_THEYRE_RUNNING, WHEN_I_JUST_HIT_THEM | Add four new rows in post-arc GDD pass. |

---

## Backlog hygiene

**Carry-forward items from prior audits:** Not re-checked here in detail — S17.2 audit (A−) carry-forward items belong to post-S17.2 backlog hygiene and are not expected to be resolved in S17.3 (different scope). S17.1 carry-forward items were covered in S17.2 planning and are not re-opened here.

**Backlog query used:** `gh issue list --repo brott-studio/battlebrotts-v2 --state open --label backlog` — not re-run as part of this plan because S17.3 scope is driven entirely by arc brief §S17.3 + Gizmo's design spec. Any new issues filed during S17.3 (drag carry-forward per S17.3-002, GDD drift carry-forward per §"GDD carry-forward") will be tagged `label:backlog` at file time.

**Framework-hygiene FYI (not S17.3 scope):** Specc flagged that `sprints/sprint-17.1.md` and `sprints/sprint-17.2.md` still show `**Status:** Planning` with unchecked exit criteria despite both being closed. **Ett decision: this is NOT an S17.3 task.** It's a framework close-out-hygiene patch that belongs to a separate small fix (either a framework change so close-out flips status automatically, or a one-off retroactive edit). Surfacing to The Bott in the return payload so it can be triaged outside the S17 arc pipeline.

---

## Pipeline flow

Standard pipeline: Ett plan (this file) → Gizmo per-task design review (esp. S17.3-002 copy wording; S17.3-004 roster-diff compliance gate) → Nutts build → Boltz review → Optic verify (screenshots of curated tray; 8-placed-card overlap check) → Specc audit → Gizmo design-validation → Ett continuation decision → Riv loops.

**Gizmo gates of note:**
- S17.3-002 empty-slot copy — Gizmo blesses the replacement wording.
- S17.3-004 — Gizmo verifies Nutts' display-dict diff matches §"Card-library roster diff" byte-for-byte before Boltz review.

**Critical:** S17.3-004 has the narrow `godot/combat/**` scope exception. Boltz must verify via diff that non-CHASE paths are byte-identical.

---

## Escalation triggers (unchanged from arc brief + sub-sprint-specific)

Auto-surface to HCD via The Bott if:
- Any proposed `godot/data/**` or `docs/gdd.md` edit.
- CHASE_TARGET implementation in `combat_sim.gd` cannot be kept purely additive (non-CHASE behavior would change).
- Nutts or Gizmo wants to modify the roster diff (add/remove/rename any card beyond §"Card-library roster diff").
- PR #77 cherry-pick surfaces merge conflicts that can't be resolved without design decisions.
- Selected-row color fix requires broader theme/stylebox refactor.
- Sub-sprint exceeds 2× expected size.

Otherwise: Riv and Ett operate autonomously per 2026-04-20 autonomy directive.

---

## Scope-streak ledger

| Sub-sprint | `godot/data/**` drift | `docs/gdd.md` drift | Status |
|---|---|---|---|
| S15.2 | 0 | 0 | clean |
| S16.1 | 0 | 0 | clean |
| S16.2 | 0 | 0 | clean |
| S16.3 | 0 | 0 | clean |
| S17.1 | 0 | 0 | clean |
| S17.2 | 0 | 0 | clean |
| S17.3 | 0 | 0 | **target** |

Six clean. Don't break the streak.
