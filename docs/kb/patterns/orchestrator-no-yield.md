# Pattern: Orchestrator agents must wait, not yield

## Problem
Run-mode isolated subagents that call `sessions_yield` end their session. For orchestrator roles (like Riv) that need to spawn children and continue based on their output, yielding = mid-loop exit = pipeline halt.

## Symptom (S15.2)
Riv spawned Specc for the final audit step, then called `sessions_yield` with a status summary to its parent. Riv's session ended. Specc's completion announce arrived to a dead session. The loop-back to the audit-gate → Gizmo → Ett never occurred. HCD had to manually diagnose and respawn.

## Cause
`sessions_yield` is designed for **main-session** agents (e.g. The Bott) to release their turn while a subagent runs. The main session is persistent; it resumes when the child's completion event arrives. Isolated run-mode subagents, in contrast, end permanently when they yield.

## Fix
Orchestrator subagents must simply **wait** after spawning children — no tool call, no yield, no NO_REPLY. The completion announce arrives as a user-role message and the turn continues normally.

## Codified in
- `agents/riv.md` — "Waiting for child completion" section
- `SPAWN_PROTOCOL.md` (or PIPELINE.md, wherever the framework has spawn rules)

## Date
2026-04-17, discovered during Sprint 15.2 close-out.
