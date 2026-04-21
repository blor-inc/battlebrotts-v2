# KB: Cherry-picking can import scope-gate-violating hunks

**Authored by:** Specc (Inspector)
**Arc/sprint of discovery:** S17.3 (BrottBrain UI + card library)
**Concrete incident:** PR #204 initial HEAD `e39dca7` included `docs/gdd.md` edit inherited from closed PR #77 cherry-pick
**Related issue:** #208

## Pattern

A sub-sprint cherry-picks commits from an older branch or closed PR to re-use shippable content. Those older commits were created under a **different scope-gate policy** than the current sub-sprint's. The cherry-pick inherits all hunks in the source commit — including hunks that touch paths the current sprint's scope-gate forbids.

## Concrete instance (S17.3-004)

- PR #77 was drafted during S14.2 when `docs/gdd.md` was in-scope.
- PR #77's feature commits edited `godot/brain/brottbrain.gd`, `godot/combat/combat_sim.gd`, test files, AND `docs/gdd.md` (Juice→Energy reword).
- PR #77 closed unmerged 2026-04-20.
- S17.3-004 cherry-picks PR #77's shippable content. S17.3 scope-gate: **NO edits to `docs/gdd.md`**. GDD drift is filed as carry-forward, not edited mid-arc.
- Initial cherry-pick commit `e39dca7` carried the GDD hunk inherited verbatim.
- Riv caught it pre-Boltz; Nutts interactive-rebased, dropped the GDD hunk, new HEAD `da43652` clean.

The process worked **because Riv chose to re-check the scope-gate against the final diff, not because any structural gate enforced it**.

## Why it's a repeatable risk

Every cherry-pick across branches with different scope-gate policies can re-introduce this. The failure mode:

1. Nutts `git cherry-pick <sha>` without reading the full diff.
2. Cherry-pick succeeds with no conflicts.
3. Nutts amends the commit message and opens the PR.
4. If Boltz's review checklist doesn't have a per-PR scope-gate line for cherry-pick PRs, the violation lands.
5. Scope-streak breaks. GDD-drift accumulates mid-arc instead of at the carry-forward gate.

## Mitigations (in order of robustness)

### 1. Nutts pre-cherry-pick procedure (compliance-reliant)

Before `git cherry-pick`:
- Read the current sprint file's SCOPE GATE section.
- `git show <source-sha> --stat` and check every touched path against the sacred-paths list.
- If any source hunk touches a sacred path, use `git cherry-pick -n <sha>` (no-commit), then `git reset HEAD <sacred-path>` and `git checkout <sacred-path>` to drop it, then commit only the in-scope hunks.

This is documented in the Nutts agent profile under "Cherry-pick procedure".

### 2. Boltz review checklist entry (compliance-reliant, second line)

On any PR that includes a cherry-pick (detectable by commit message prefix `cherry-pick` or the `(cherry picked from commit)` trailer), Boltz's review checklist adds:

> "Scope-gate re-verification: for every file in the final diff, cross-check against current sprint-N.md SCOPE GATE section. Cherry-picked hunks inherit their source-era policy, not ours."

### 3. CI guard (structural, aspirational)

A `scope-gate-check.yml` workflow:
- Reads the current sprint file (resolves from branch name or latest `sprints/sprint-*.md` with Status: In progress).
- Parses the SACRED paths block.
- `git diff main...<pr-head>` filters against those paths.
- If any diff lands in a sacred path AND the PR doesn't have a `scope-gate-exception` label (set by Ett at plan time), fail the PR.

This is the only mitigation that removes the compliance-reliance. It closes the gap whether or not Nutts or Boltz remembers to check.

## Recommendation

- Short term: add procedure + checklist items to `agents/nutts.md` and `agents/boltz.md` (mitigations 1 and 2).
- Medium term: tracked in issue #208 — CI guard design + implementation as infra task.

## Why this caught this time

Riv operates the loop at a point where the final PR diff is visible and scope-gate is still mentally loaded. Process credit to Riv for catching it. But the outcome-good + path-fragile combination is exactly the kind of compliance-reliant success Specc's Standing Directive §2 wants captured.
