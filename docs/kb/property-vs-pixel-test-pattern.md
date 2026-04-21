# KB: Property-value vs pixel-output test assertions for UI

**Authored by:** Specc (Inspector)
**Arc/sprint of discovery:** S17.3 (BrottBrain UI + card library)
**Concrete incident:** PR #204 S17.3-004 AC3 — selected-row blue tint
**Related issues:** #205 (concrete instance), #207 (pattern doc)

## Pattern

A Godot test asserts a Node's visual property (e.g. `modulate`, `color`, `position`) equals the expected value. The test passes. The feature still visually fails because the property was **set** but did not **affect the rendered pixel**.

## Why property-assertions can lie

Setting a property only changes the Node's state. Whether that state reaches the framebuffer depends on the full draw pipeline:

1. **The Node has no draw output.** A `Button` with `flat = true` and empty text/icon draws nothing. `modulate` multiplies zero. No pixel changes. (This is how S17.3-004 AC3 failed.)
2. **Parent modulate cancels it.** A `CanvasItem`'s final modulate is parent × self. If a parent is translucent or tinted, the child's intended color is multiplied away.
3. **StyleBox / theme overrides the draw.** A Button with a StyleBoxFlat using a hard-coded `bg_color` draws that color regardless of `modulate` in certain draw paths.
4. **Z-order / clipping.** The Node is drawn, but something in front or a clip_children mask hides it.
5. **Viewport / visibility.** The Node is outside the viewport rect, has `visible = false` on an ancestor, or is scaled to zero.

In every case, the property equals the expected value. The assertion passes. The user sees nothing.

## The test false-positive

```gdscript
# WRONG — property-only
assert(select_btn.modulate == Color(0.3, 0.6, 1.0, 0.3))  # passes, but user sees gray
```

```gdscript
# RIGHT — pixel-sampled
var img := get_viewport().get_texture().get_image()
var row_center := Vector2i(400, card_y_center_px)
var sampled := img.get_pixelv(row_center)
assert(sampled != Color(46, 46, 46))  # panel background; any real tint shifts this
```

## Recommended rule

**Visual ACs require pixel assertions.** If the AC is of the form "the selected row is tinted blue", "the delete button appears red", "card tray does not overlap nav buttons at 8 cards" — the test MUST render a frame and sample pixels or bounding rectangles. A property assertion alone is insufficient.

**Behavioral ACs stay with property / signal assertions.** "Clicking the card calls `_select_card(index)`" — property/signal-level is correct here.

## Helper (suggested, to be added to test framework)

```gdscript
# godot/tests/helpers/pixel_sample.gd
static func sample_at(scene: Node, coord: Vector2i) -> Color:
    # Render one frame of scene headlessly, return pixel at coord.
    var viewport := SceneTree.root.get_viewport()
    await RenderingServer.frame_post_draw
    var img := viewport.get_texture().get_image()
    return img.get_pixelv(coord)

static func assert_visible_tint(scene: Node, coord: Vector2i, expected_tint: Color, tolerance: float = 0.02) -> bool:
    var actual := await sample_at(scene, coord)
    return actual.is_equal_approx_tol(expected_tint, tolerance)
```

## Related rules (add to `CONVENTIONS.md`)

- Any test whose AC starts with "is visually …" or "the user sees …" must pixel-sample, not property-assert.
- Any visual overlap AC ("non-overlapping at N elements") must compare bounding rectangles, not just positions.
- Unit tests can stay at the property level when the AC is behavioral (event was fired, state mutated, handler was invoked).

## Why this matters

S17.3-004 shipped with a property-passing, pixel-failing test. Boltz reviewed the diff and test and saw the assertion pass. Optic caught it at post-merge verify — too late to block the ship. The pipeline's test layer was blind to its own false positive. Adding pixel assertions at unit-test time keeps the build honest without relying on Optic as the last line of defense.
