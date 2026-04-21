# Sprint 17.4 — BrottBrain visual polish (close-out of S17 Eve Polish Arc)

**PM:** Ett
**Status:** Planning
**Sprint type:** Sub-sprint 4 of 4 (S17 Eve Polish Arc)
**Iteration sizing target:** Small–medium (2 required tasks + 1 stretch)
**Preceded by:** S17.3 (BrottBrain UI + card-library curation) — audit grade **B+**, pipeline clean, two visual ACs shipped broken as data (#205, #206).

---

## Cadence note — 4th sub-sprint past the arc-brief's planned 3

The S17 arc brief (`sprints/sprint-17.md`) originally scoped three sub-sprints (S17.1 medium, S17.2 medium, S17.3 medium-large). No numeric max-sprints fuse was set. S17.4 is a fourth sub-sprint added to close the arc-acceptance bar (bullets 1 + 5 — "no original-playtest frustrations" and "playtest-ready drop") which Gizmo's Phase 1 arc-intent verdict flagged as **`arc-intent-blocked`** due to #205 (BrottBrain selected-row tint invisible) and #206 (tray/nav overlap at `MAX_CARDS==8`, prio:high, user-visible at canonical state).

This sub-sprint is deliberately kept narrow: two focused fixes in a single file (`godot/ui/brottbrain_screen.gd`) + an optional hygiene stretch. If S17.4 does not close the acceptance bar, **escalate to HCD** rather than roll a S17.5 silently.

---

## 🛑 SCOPE GATE — READ FIRST

Inherits the S17 arc-brief gate (`sprints/sprint-17.md` §"SCOPE GATE") and the S17.3 gate in full. For S17.4 specifically:

- **Primary touch zone:** `godot/ui/brottbrain_screen.gd` (and its companion tests under `godot/tests/`).
- **No** edits to `godot/data/**` (weapon/chassis/armor data).
- **No** edits to `docs/gdd.md`. GDD-DRIFT-1/2/3 + GDD-ADD-1 remain on post-arc carry-forward; docs-only reconciliation PR lands after arc-close, not mid-arc.
- **No** edits to `godot/arena/**`.
- **No** edits to `godot/combat/**` (no S14.2-canon CHASE/trigger wiring needed this sub-sprint — already shipped in S17.3-004).
- **Tests:** additive-only. Pixel-sample test pattern lands as new helper + new assertions (#207 reference fix). No loosening of currently-passing assertions.
- **Scope-streak ledger:** going in at **7** (held clean S15.2 → S16.1 → S16.2 → S16.3 → S17.1 → S17.2 → S17.3). Target **8** on S17.4 close.

If a task drifts into "let's also fix X while we're in `brottbrain_screen.gd`" — STOP and carry-forward.

Full framework reference: `sprints/sprint-17.md` §"SCOPE GATE", §"Sacred", §"Explicitly out of scope", §"Escalation triggers".

---

## Goal

Close the two visual defects blocking the S17 arc-acceptance bar so the arc can ship a **playtest-ready BrottBrain drop**. Both defects were identified in the S17.3 post-merge audit (#205, #206) and specced end-to-end by Gizmo in Phase 1 of this sub-sprint — this sub-sprint packages Gizmo's fix specs into executable tasks, wires them through the standard pipeline, and folds the #207 property-vs-pixel test-pattern fix in as a reference implementation alongside #205. No redesign work; the numbers are set, the root causes are traced, the AC is concrete.

---

## Tasks

### **[S17.4-001]** Fix #205 — BrottBrain selected-row blue tint visible + land the pixel-sample test pattern (#207)

**Primary agents:** Nutts (build) → Boltz (review) → Optic (visual verify) → Specc (audit)

**Source issues:**
- **#205** (prio:mid, area:ux) — Selected-row tint invisible.
- **#207** (prio:mid, area:tests) — Property-value assertions pass while pixel output fails. This task's test pattern doubles as the #207 reference fix.

**Root cause (from Gizmo Phase 1 spec):** the row is rendered as a flat `Button` with empty text; Godot's flat-button modulate path has no colored fill to tint, so `modulate` silently no-ops. The S17.3 property-assertion test checked `modulate != Color.WHITE` on a node whose rendered pixels were unaffected — test passed, pixels didn't change.

**Fix (verbatim from Gizmo spec):**
- Replace the modulate pattern with a **ColorRect overlay pair**:
  - A `ColorRect` painted **beneath** a flat click-capture `Button`.
  - Overlay bounds: `(600, 55)`.
  - Overlay `mouse_filter = MOUSE_FILTER_IGNORE` (the Button above handles clicks).
  - Selected color: `Color(0.3, 0.6, 1.0, 0.3)`.
  - Unselected color: transparent (`Color(0, 0, 0, 0)`).

**Acceptance:**
- AC1: When a BrottBrain row is selected, the rendered pixels over the row's overlay bounds show a visible blue tint.
- AC2: **Pixel-sample test assertion** (not property assertion) in `godot/tests/`:
  - Sample a pixel inside the selected row's overlay bounds and an equivalent pixel inside an unselected row's overlay bounds.
  - Assert `selected_pixel.b > selected_pixel.r + 0.05` **AND** `selected_pixel.b > unselected_pixel.b + 0.05`.
- AC3: Clicking the row still selects it (click-capture Button on top, `mouse_filter=IGNORE` on overlay).
- AC4: No regression in existing BrottBrain tests; no new failures elsewhere.
- AC5: Optic Playwright/visual run: screenshot diff shows the blue tint on selected row.

**Scope-gate note:** touches `godot/ui/brottbrain_screen.gd` + `godot/tests/` (additive). No other files.

---

### **[S17.4-002]** Fix #206 — BrottBrain tray/nav overlap at MAX_CARDS=8 via ScrollContainer + fixed tray anchor

**Primary agents:** Nutts (build) → Boltz (review) → Optic (visual verify) → Specc (audit)

**Source issue:**
- **#206** (prio:high, area:ux) — Tray/nav overlap at 8 cards. User-visible at canonical `MAX_CARDS==8`.

**Root cause (verified math from Gizmo Phase 1 spec):**
- Cards render at y=132–572.
- Tray starts at y=587, then row wraps to y=698.
- Nav buttons pinned at y=650–700.
- Collision: tray second row (y=698) overlaps nav (y=650–700).

**Fix (verbatim from Gizmo spec — Option (c)):**
- Wrap the card-draw region in a `ScrollContainer`:
  - Size: `(770, 220)`.
  - Position: `(20, 132)`.
  - `vertical_scroll_mode = SCROLL_MODE_AUTO` (scrollbar appears only when content overflows; no whitespace/scrollbar for `cards.size() < 4`).
- Decouple tray position from card count:
  - `tray_y_base = 370` (fixed, independent of `cards.size()`).
- Reorder buttons:
  - `btn_x = 820`.
- Result (math-verified): tray end-y ≈ 505, well clear of nav y=650.

**Acceptance:**
- AC1: At `MAX_CARDS == 8`, **zero pixel overlap** between tray elements and nav buttons.
- AC2: Card-draw region scrolls when `cards.size() >= 5` (or whenever cards overflow the `(770, 220)` container).
- AC3: Nav buttons unchanged at y=650.
- AC4: Tray end-y at 8 cards matches tray end-y at 0 cards within ±5px (proves tray is decoupled from count).
- AC5: `vertical_scroll_mode = SCROLL_MODE_AUTO` — when `cards.size() < 4`, no scrollbar and no whitespace visible.
- AC6: Optic Playwright run with `MAX_CARDS=8` scenario: screenshot confirms no overlap; scrollbar appears only when overflow.
- AC7: Pixel-sample or bounds-check test assertion confirming AC1 and AC4 (reuse helper from S17.4-001 where applicable).

**Scope-gate note:** touches `godot/ui/brottbrain_screen.gd` + `godot/tests/` (additive). No other files. No changes to nav-button screen.

---

### **[S17.4-003]** *(STRETCH — cut if sizing pressure)* Hygiene: dedupe test_runner.gd (#211) + enum-ordinal cleanup (#212)

**Primary agents:** Nutts (build) → Boltz (review) → Specc (audit).

**Source issues:**
- **#211** (prio:low, area:tests) — `godot/tests/test_runner.gd` lists `test_s17_2_scout_feel.gd` twice (duplicate line).
- **#212** (prio:low, area:tech-debt) — `brottbrain_screen.gd` uses raw enum ordinals for pct/tiles phrasing.

**Fix:**
- #211: Remove the duplicate `test_s17_2_scout_feel.gd` entry from `godot/tests/test_runner.gd`. One-line change.
- #212: Replace raw enum ordinals in pct/tiles phrasing branches with named enum references. No behavior change — readability only.

**Acceptance:**
- AC1 (#211): `test_runner.gd` contains `test_s17_2_scout_feel.gd` exactly once. Full test suite still runs green.
- AC2 (#212): No raw integer ordinals remain in pct/tiles phrasing branches; named enum references used throughout. Existing phrasing-output tests unchanged and still green.

**Cut rule:** if S17.4-001 and S17.4-002 take longer than expected, drop S17.4-003 and carry #211/#212 forward. Do not trade scope gate for stretch hygiene.

---

## Dependencies

- S17.4-001 and S17.4-002 can run in parallel (both touch `godot/ui/brottbrain_screen.gd`; Nutts should sequence merges to avoid rebase churn, but design work is independent).
- S17.4-003 depends on 001 + 002 landing first (small cleanup goes last to avoid rebase drag on the main fixes).
- Pixel-sample test helper from S17.4-001 should land before S17.4-002's pixel-overlap assertion so 002 can reuse it.

---

## GDD carry-forward (unchanged — still deferred mid-arc)

Inherited from S17.3. Do **not** edit `docs/gdd.md` in S17.4. Carry-forward items remain:

- **GDD-DRIFT-1:** Juice → Energy terminology rename in GDD (live code uses "Energy"; GDD still says "Juice" in places).
- **GDD-DRIFT-2:** Roster table sync — cards added in S17.3-004 not yet reflected in GDD card roster.
- **GDD-DRIFT-3:** Roster table sync — triggers added in S17.3-004 not yet reflected in GDD trigger roster.
- **GDD-ADD-1:** Four new card rows added in S17.3-004 need full GDD entries.

Gizmo has flagged these for a **post-arc-close docs-only GDD reconciliation PR** — see arc-close handoff. Arc-close PR is out of S17.4 scope.

---

## Backlog hygiene (cross-reference vs. S17.3 audit carry-forward)

All 9 items flagged by the S17.3 audit are filed as open GitHub issues on `brott-studio/battlebrotts-v2`:

- `#201` carry-forward real drag-to-reorder — **carried forward** (future polish arc, not S17).
- `#205` — addressed in S17.4-001.
- `#206` — addressed in S17.4-002.
- `#207` — addressed via the pixel-sample test pattern in S17.4-001.
- `#208` cherry-pick scope-gate violation risk — **carried forward** (framework tightening; not S17 in-scope).
- `#209` sprint-plan canon wording — **carried forward** (framework doc cleanup).
- `#210` Boltz self-approve (shared PAT) — **carried forward** per arc-brief §"Per-agent App usage" (explicitly deferred HCD action).
- `#211` — addressed in S17.4-003 (stretch).
- `#212` — addressed in S17.4-003 (stretch).

**No backlog gap.** #201 + #208 + #209 + #210 carry forward past arc-close with Ett's explicit rationale above.

---

## Pipeline flow

Standard: **Gizmo (embedded — Phase 1 already delivered two fix specs) → Ett (this plan) → Nutts (build) → Boltz (review) → Optic (verify) → Specc (audit) → Gizmo (design validation) → Ett (continuation decision — next spawn)**.

For S17.4 specifically:
- Gizmo Phase 1 output is authoritative for the #205 and #206 fix numbers. Nutts implements the numbers verbatim; does not re-design.
- Optic's visual check is gating on both AC1 (#205) and AC1/AC6 (#206). These are pixel-level visual ACs — property assertions alone are insufficient (that was the S17.3 failure mode).
- Specc audit must confirm pixel-sample test assertions are in place (not property-only) before closing S17.4.

---

## Escalation triggers

Inherits arc-level triggers (`sprints/sprint-17.md` §"Escalation triggers"). Additional for S17.4:

- **Render architecture (🔴):** if the #205 ColorRect-overlay fix surfaces cross-cutting render architecture issues in Godot (e.g., z-ordering, theme overrides, or viewport issues affecting other screens), **stop and escalate**. Do not expand scope to a render refactor mid-sub-sprint.
- **Scroll architecture (🔴):** if the #206 ScrollContainer fix reveals that other BrottBrain UI elements (tray, nav) also depend on the old card-region layout in non-obvious ways, **stop and escalate** rather than cascading changes.
- **AC-miss (🔴):** if either #205 or #206 cannot meet its pixel-level AC with the Gizmo-specced numbers, stop and escalate to HCD. Don't re-design in-flight; don't loosen the AC.
- **Sub-sprint over-size (🔴):** S17.4 is scoped small–medium. If it exceeds 2× that (i.e. tracking toward large), escalate to HCD — per my Ett profile, "Sub-sprint exceeds 2× expected size" is an auto-surface trigger.
- **Arc close-out:** if S17.4 lands both ACs green, next Ett spawn should mark **arc-complete** (Gizmo's Phase 1 verdict will presumably shift from `arc-intent-blocked` back to `satisfied`). Riv + The Bott prep the post-arc GDD reconciliation PR immediately after close.

---

## Scope-streak ledger

- Entering S17.4: **7** (held clean S15.2 → S16.1 → S16.2 → S16.3 → S17.1 → S17.2 → S17.3).
- Target on S17.4 close: **8**.
- S17.4 risk area: `godot/ui/brottbrain_screen.gd` edits staying off `godot/data/**`, `docs/gdd.md`, `godot/arena/**`, and `godot/combat/**`. All four are well-fenced; risk is low.

---

## Out of scope for S17.4 (explicit)

- Real drag-to-reorder (#201) — future polish arc.
- Boltz per-agent App (#210) — deferred HCD action.
- Cherry-pick scope-gate tightening (#208) — framework work, post-arc.
- Sprint-plan canon wording (#209) — framework doc cleanup, post-arc.
- GDD reconciliation (GDD-DRIFT-1/2/3, GDD-ADD-1) — post-arc docs-only PR.
- Any new BrottBrain feature work — arc-close is the goal.
- Any `godot/combat/**` edits — S14.2-canon wiring already shipped in S17.3-004.
