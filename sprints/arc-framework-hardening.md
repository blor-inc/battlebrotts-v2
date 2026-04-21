# Arc: Framework Hardening

**Status:** Docketed. To launch after S17 Eve Polish Arc closes.
**Type:** Framework arc (not game-content).
**Sponsor:** HCD (approved 2026-04-21).
**Origin:** Root-cause of S17.1-005 audit-gate bypass + framework self-sufficiency gap surfaced during S17.

---

## Why this arc

1. **Process-breach root cause (S17.1-005):** PR #171 merged before Optic verified. Root cause: the audit gate is a prompt convention, not a structural check. Branch protection has no way to require "Optic verified" — Specc could auto-merge on green CI + 1 approval alone. Need structural enforcement.
2. **Framework self-sufficiency gap:** A fresh session starting a new project today cannot cleanly adopt the studio pipeline. `FRAMEWORK.md` contradicts `PIPELINE.md` (Riv-retired vs Riv-canon), no `BOOTSTRAP_NEW_PROJECT.md`, secrets and CI-gate names are hardcoded to BattleBrotts, `ESCALATION.md` is orphaned under `docs/kb/`. Known since 2026-04-17 self-sufficiency audit; partially addressed.
3. **Drift prevention:** Without a structural test, framework self-sufficiency will regress every arc as new BattleBrotts-specific conventions leak in.

---

## Scope

### 1. Optic as a structural gate (P0 — addresses S17.1-005 breach)
- Create `brott-studio-optic` GitHub App (same pattern as Specc).
- Optic subagent posts `Optic Verified` check-run via Checks API on verify completion.
- Add `Optic Verified` to required status checks on `main` branch protection.
- Specc cannot auto-merge until Optic has structurally affirmed verify pass.
- Update `studio-framework/agents/optic.md` + `specc.md` to document the new flow.

### 2. Framework self-sufficiency (P0)
- Promote `docs/kb/escalation-policy.md` → `ESCALATION.md` at studio-framework root + cross-reference from all agent profiles.
- Resolve Riv-retired contradiction in `FRAMEWORK.md` (Riv + Ett are canon per 2026-04-17 HCD decision).
- Write `BOOTSTRAP_NEW_PROJECT.md`: the concrete 5-step setup for a fresh project (repo creation, per-agent App bootstrap, secrets provisioning, CI-gate configuration, first-arc spawn recipe).
- Abstract CI-gate names: agent profiles reference configurable gate names, not hardcoded `Godot Unit Tests` / `Playwright Smoke Tests`.
- Document per-agent GitHub App bootstrap procedure (creation, installation, token-file convention).

### 3. Cold-start validation (P1 — prevents future drift)
- Add arc-close protocol step: spawn a fresh subagent with *only* the `studio-framework` repo clone, ask it to plan Sprint 1 of a hypothetical new project.
- Any blocking question the cold-start agent asks becomes a framework PR before the next arc launches.
- Cold-start test runs ~10 min at each arc-close. Cheap to maintain.

### 4. Branch protection tightening (P2)
- Remove Specc from `bypass_pull_request_allowances` (Specc should merge via App, but only after an actual review).
- Enable `enforce_admins` to close the admin-bypass footgun.
- Apply same protection rules to `brott-studio/studio-audits`.

### 5. CODEOWNERS — DEFERRED / DECLINED (documented decision)
- HCD does not want to be in the PR-review critical path. Creative-authority enforcement via HCD approval was considered and declined in favor of structural gates (Optic check, Specc-with-receipts pattern).
- Sacred-path concept retained as a scope-gate in agent prompts (existing), but not structurally enforced via CODEOWNERS. Revisit only if a concrete sacred-path breach occurs.

---

## Acceptance criteria

- [ ] `Optic Verified` check is required on `main`, blocks Specc merges until Optic posts success.
- [ ] Recreating the S17.1-005 sequence (Specc tries to merge before Optic verifies) is **physically impossible** — branch protection blocks it.
- [ ] `ESCALATION.md` at studio-framework root, cross-referenced by all 8 agent profiles.
- [ ] `FRAMEWORK.md` and `PIPELINE.md` internally consistent on Riv + Ett canon.
- [ ] `BOOTSTRAP_NEW_PROJECT.md` exists and a cold-start agent can follow it to completion without blocking questions.
- [ ] Cold-start validation step documented in Riv's arc-close protocol.
- [ ] `enforce_admins` enabled on `main` for battlebrotts-v2 and studio-audits.
- [ ] Specc removed from bypass list.

---

## Sub-sprint shape (tentative — Gizmo/Ett to refine)

- **F.1** Optic App + structural check (CI workflow + Optic profile update + branch protection update).
- **F.2** Framework self-sufficiency pass (ESCALATION promotion, FRAMEWORK reconciliation, BOOTSTRAP_NEW_PROJECT.md, CI-gate abstraction).
- **F.3** Cold-start validation + arc-close protocol update.
- **F.4** Branch protection tightening (bypass removal, enforce_admins).

---

## Notes for the next Riv

- This is a **framework arc**, not a game-content arc. Most work lands in `studio-framework` repo, not `battlebrotts-v2`. F.1 and F.4 land in both (battlebrotts-v2 for branch protection, studio-framework for agent profile updates).
- No sacred-path concern — this arc doesn't touch game data/combat/arena/GDD.
- HCD involvement expected to be minimal (design check-ins only, no PR reviews).
- Arc-close cold-start test is itself a deliverable of this arc — run it *on this arc's own output* before declaring the arc done.
