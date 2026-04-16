# KB: Infrastructure Nodes Freed by UI Rebuild

**Source:** Sprint 13.5 audit (PR #62, Bug 1 caught by Boltz)
**Category:** Godot / UI Architecture

## Pattern

An "infrastructure" node — `AudioStreamPlayer`, `Timer`, `Tween`, etc. —
is parented inside a UI container that gets wiped and rebuilt on every
`_build_ui` call. The node reference is held as a class field, so the
field stays populated (technically pointing at a freed object), and
calls against it either silently no-op (Godot's freed-instance
semantics) or crash, depending on what's being called and when.

The bug is often **silent**: no stack trace, no error log, the feature
just doesn't work.

## Example (Sprint 13.5)

`shop_screen.gd` rewritten in S13.4 introduced `_build_ui()` which
wipes and rebuilds the shop container's children on every refresh.
S13.5's SFX scaffold added `_shop_audio: AudioStreamPlayer` as a child
of that container. First `_build_ui` call after shop state change
freed `_shop_audio`. All subsequent `_play_sfx()` calls no-op'd
because the `_play_sfx` helper uses a safe-load pattern that
gracefully skips when the node is invalid.

Result: shop SFX silently never fired. Tests passed (they checked
that `_play_sfx` was callable, not that audio played). Boltz caught
it on second-pass review.

A second, related bug in the same PR: `_seen_shop_items` as a
per-instance field meant the "new item" pulse re-fired every time
the shop was re-opened, because the `ShopScreen` instance itself was
being recreated. Fix: `static var _seen_shop_items` so persistence
survives across instances. Same root-cause family — **state that
should outlive a rebuild was scoped to something that doesn't**.

## Mitigation

When adding infrastructure nodes (audio, timers, tweens, persistent
state) to a UI that rebuilds its tree:

1. **Parent infra nodes outside the rebuildable subtree.** Put them
   on the screen root, not on a container that `_build_ui` wipes.
2. **Or re-acquire after every rebuild.** If they must live inside
   the rebuildable tree, treat the class field as a cache that must
   be re-populated at the end of every `_build_ui`.
3. **For persistence across instances,** use `static var` or route
   through a singleton / autoload, not per-instance fields.
4. **In review,** for any class with a `_build_ui` / `_rebuild` /
   `_refresh` method, explicitly ask: *"What class fields point at
   nodes inside the rebuilt subtree? Are they still valid after
   rebuild?"*

## Review Checklist Addition

- [ ] Any class field of type `Node` (or subclass) — is the node it
      points at inside a container that gets `queue_free`'d or
      child-wiped during normal operation?
- [ ] Any state that should persist across scene/UI re-instantiation
      — is it `static`, in an autoload, or saved?
- [ ] Any "safe" helper that silently no-ops on bad input — does it
      mask a real bug by swallowing the failure?

## Related

- `latent-bugs-inactive-paths.md` — same class of "silent until
  activated" failure mode, but triggered by deferred features rather
  than tree lifecycle.
