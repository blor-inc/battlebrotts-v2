# KB: Godot `Button` with `flat = true` and no text/icon is unmodulatable

**Authored by:** Specc (Inspector)
**Arc/sprint of discovery:** S17.3 (BrottBrain UI + card library)
**Concrete incident:** PR #204 S17.3-004 AC3 — selected-row blue tint never painted
**Related issue:** #205

## Pattern

A Godot `Button` Node with `flat = true` and no `text` / `icon` has no draw output. Setting `modulate` on that Node has no visual effect — there's nothing to multiply. The Node remains click-capturable (it still receives `_pressed` signals and occupies hit-test area) but draws zero pixels.

If a UI pattern uses such a Button as an **invisible click overlay** over a card/panel, any attempt to tint the overlay on selection will silently fail.

## Concrete instance (S17.3-004)

`godot/ui/brottbrain_screen.gd:330–336`:
```gdscript
select_btn.flat = true
select_btn.text = ""  # no content
if index == selected_card_index:
    select_btn.modulate = Color(0.3, 0.6, 1.0, 0.3)  # blue, 30% alpha
else:
    select_btn.modulate = Color(1, 1, 1, 0.01)  # near-invisible click overlay
```

- `select_btn` is a click-capture overlay over the card `Panel`.
- `modulate` is set correctly per property-level assertion (test passes).
- No visual tint appears. Optic pixel-sample: `(46,46,46)` selected == unselected.
- Root cause: `flat=true` + empty text → no draw call → modulate has no target.

## Godot-idiomatic fixes

### Option A — Paint on the backing Panel
Apply the tint to the card's `Panel` Node directly (StyleBox bg_color swap), keep Button as click-only. Panel has a visible StyleBox; its `modulate` or its StyleBoxFlat's `bg_color` reaches the framebuffer.

### Option B — Use a ColorRect overlay
Replace the invisible Button with a `ColorRect` sized to the card panel. Set `ColorRect.color` for the tint. Keep a separate Button on top (or use `_gui_input` on the panel) for click capture.

### Option C — Give the Button visible drawing
`flat = false` + a StyleBoxFlat with `bg_color` set per state (normal / hover / pressed). The Button now draws its background and can be modulated or colored.

Option A is the simplest for the BrottBrain case since the card panel already exists.

## Rule of thumb

**If a Control Node has `visible = true` but produces no draw call (no text, no icon, no Rect fill, no StyleBox), `modulate` is a silent no-op. Any test asserting visual effect through that Node must pixel-sample, not property-check.**

Related KB: `property-vs-pixel-test-pattern.md` (issue #207) — this is one concrete case of a broader class of false-positive.

## Detection

Quick debugger check:
- In `_process` or on frame tick, `print(select_btn.get_rect())` — confirms hit area exists.
- `print(select_btn.has_theme_stylebox("normal"))` — confirms whether any draw comes from theme.
- If both yield "area exists but no drawing pipeline", the Button is unmodulatable in the visual sense.

## References

- Godot docs: `CanvasItem.modulate` multiplies the Node's own draw color. See https://docs.godotengine.org/en/stable/classes/class_canvasitem.html#property-modulate
- Godot docs: `Button.flat` disables the default StyleBox. See https://docs.godotengine.org/en/stable/classes/class_button.html
