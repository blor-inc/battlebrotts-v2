## S21.4 / T1 / #105 — Scroll position preserved in shop and loadout on child-node tap.
## Usage: godot --headless --script tests/test_s21_4_001_scroll_position.gd
##
## Spec Invariants tested:
##   I-A1. ScrollContainer in shop view MUST NOT reset scroll offset on child-node tap.
##   I-A2. ScrollContainer in loadout view MUST NOT reset scroll offset on child-node tap.
##   I-A4. load scene, scroll to offset Y_nonzero, simulate child-node tap,
##          re-read scroll offset → MUST equal Y_nonzero (±tolerance for rounding only).
##
## Root cause addressed: loadout_screen.gd ScrollArea had follow_focus=true, which
## caused Godot to auto-scroll to the focused Button on every press, resetting the
## user's scroll position. Fixed by setting follow_focus=false and adding the
## save/restore pattern (matching shop_screen.gd S17.1-001).
##
## NOTE: shop_screen.gd already had the save/restore pattern from S17.1-001.
## test_sprint17_1_shop_scroll.gd covers shop AC-1–AC-5.
## This file adds cross-scene invariant tests per I-A1/I-A2/I-A4, and the
## loadout-specific tap-preserves-scroll tests that were missing before S21.4.
extends SceneTree

const SCROLL_TOLERANCE := 2  # px tolerance for int/float rounding

var pass_count := 0
var fail_count := 0
var test_count := 0

func _initialize() -> void:
	print("=== S21.4-001 Scroll Position Tests (shop + loadout) ===\n")
	_test_shop_scroll_preserved_on_card_tap()
	_test_loadout_scroll_preserved_on_item_tap()
	_test_loadout_scroll_starts_at_zero()
	print("\n=== Results: %d passed, %d failed, %d total ===" % [pass_count, fail_count, test_count])
	quit(1 if fail_count > 0 else 0)

# --- Assertion helpers ---

func _assert_eq(a, b, msg: String) -> void:
	test_count += 1
	if a == b:
		pass_count += 1
	else:
		fail_count += 1
		print("  FAIL: %s (got %s, expected %s)" % [msg, str(a), str(b)])

func _assert_true(cond: bool, msg: String) -> void:
	test_count += 1
	if cond:
		pass_count += 1
	else:
		fail_count += 1
		print("  FAIL: %s" % msg)

func _assert_near(a: int, b: int, tol: int, msg: String) -> void:
	test_count += 1
	if abs(a - b) <= tol:
		pass_count += 1
	else:
		fail_count += 1
		print("  FAIL: %s (got %d, expected ~%d ± %d)" % [msg, a, b, tol])

# --- Shop fixture ---

func _make_shop(bolts: int = 9999) -> ShopScreen:
	for c in root.get_children():
		if c is ShopScreen:
			root.remove_child(c)
			c.free()
	ShopScreen._seen_shop_items = {}
	var gs := GameState.new()
	gs.bolts = bolts
	var shop := ShopScreen.new()
	root.add_child(shop)
	shop.setup_for_viewport(gs, 1280)
	return shop

func _shop_scroll(shop: ShopScreen) -> ScrollContainer:
	return shop.get_node_or_null("ScrollArea") as ScrollContainer

func _shop_first_card(shop: ShopScreen) -> Button:
	var cards := shop.find_children("Card_*", "Button", true, false)
	for c in cards:
		if c is Button and not bool(c.get_meta("owned")):
			return c as Button
	return null

# --- Loadout fixture ---

func _make_loadout(item_count: int = 8) -> LoadoutScreen:
	for c in root.get_children():
		if c is LoadoutScreen:
			root.remove_child(c)
			c.free()
	var gs := GameState.new()
	gs.owned_chassis = [0]
	gs.equipped_chassis = 0
	# Populate enough items so scroll has room (>520 px of content)
	gs.owned_weapons = []
	gs.owned_armor = []
	gs.owned_modules = []
	gs.equipped_weapons = []
	gs.equipped_armor = 0
	gs.equipped_modules = []
	for i in range(item_count):
		gs.owned_weapons.append(i % 7)
	var screen := LoadoutScreen.new()
	root.add_child(screen)
	screen.setup(gs)
	return screen

func _loadout_scroll(screen: LoadoutScreen) -> ScrollContainer:
	return screen.get_node_or_null("ScrollArea") as ScrollContainer

func _loadout_first_item_button(screen: LoadoutScreen) -> Button:
	# Find the first clickable item Button inside the ScrollArea content.
	var content := screen.get_node_or_null("ScrollArea/Content")
	if content == null:
		return null
	for child in content.get_children():
		var btn: Node = child.find_child("Button", true, false)
		if btn != null and btn is Button:
			return btn as Button
	return null

# --- Test: I-A1 — shop scroll preserved on card tap ---

## I-A1 / I-A4: Shop ScrollContainer MUST NOT reset scroll offset on card tap.
## Pattern: setup shop, set scroll to Y=400, tap first unowned card, verify
## scroll offset equals Y=400 after rebuild (±tolerance).
func _test_shop_scroll_preserved_on_card_tap() -> void:
	print("I-A1/I-A4: shop scroll preserved on card tap")
	var shop := _make_shop()
	var s := _shop_scroll(shop)
	_assert_true(s != null, "[I-A1] ShopScreen has ScrollArea")
	if s == null:
		return

	s.scroll_vertical = 400
	var before := s.scroll_vertical
	_assert_true(before > 0, "[I-A1] set non-zero scroll baseline (got %d)" % before)

	var card := _shop_first_card(shop)
	_assert_true(card != null, "[I-A1] found an unowned card to tap")
	if card == null:
		return
	card.pressed.emit()

	await process_frame
	await process_frame

	var s2 := _shop_scroll(shop)
	_assert_true(s2 != null, "[I-A1] ScrollArea exists after rebuild")
	if s2 != null:
		_assert_near(s2.scroll_vertical, before, SCROLL_TOLERANCE,
			"[I-A1/I-A4] shop scroll preserved across card tap (before=%d, after=%d)" % [before, s2.scroll_vertical])

	for c in root.get_children():
		if c is ShopScreen:
			root.remove_child(c)
			c.free()

# --- Test: I-A2 — loadout scroll preserved on item tap ---

## I-A2 / I-A4: Loadout ScrollContainer MUST NOT reset scroll offset on item tap.
## Root cause being tested: follow_focus=true caused auto-scroll to focused node.
## Fix: follow_focus=false + save/restore pattern.
func _test_loadout_scroll_preserved_on_item_tap() -> void:
	print("I-A2/I-A4: loadout scroll preserved on item tap")
	var screen := _make_loadout(8)
	var s := _loadout_scroll(screen)
	_assert_true(s != null, "[I-A2] LoadoutScreen has ScrollArea")
	if s == null:
		return

	s.scroll_vertical = 200
	var before := s.scroll_vertical
	_assert_true(before > 0, "[I-A2] set non-zero scroll baseline (got %d)" % before)

	var btn := _loadout_first_item_button(screen)
	_assert_true(btn != null, "[I-A2] found item button to tap")
	if btn == null:
		return
	btn.pressed.emit()

	await process_frame
	await process_frame

	var s2 := _loadout_scroll(screen)
	_assert_true(s2 != null, "[I-A2] ScrollArea exists after rebuild")
	if s2 != null:
		_assert_near(s2.scroll_vertical, before, SCROLL_TOLERANCE,
			"[I-A2/I-A4] loadout scroll preserved across item tap (before=%d, after=%d)" % [before, s2.scroll_vertical])

	for c in root.get_children():
		if c is LoadoutScreen:
			root.remove_child(c)
			c.free()

# --- Test: I-A3 / regression guard — loadout initial scroll starts at 0 ---

## I-A3: Scroll offset at scene entry starts at 0 (no accidental non-zero restore
## on first build). Also asserts follow_focus=false is in effect (scroll does not
## jump to first button position after initial layout).
func _test_loadout_scroll_starts_at_zero() -> void:
	print("I-A3: loadout initial scroll_vertical == 0 on fresh setup")
	var screen := _make_loadout(4)
	var s := _loadout_scroll(screen)
	_assert_true(s != null, "[I-A3] LoadoutScreen has ScrollArea")
	if s != null:
		await process_frame
		await process_frame
		_assert_eq(s.scroll_vertical, 0, "[I-A3] initial scroll_vertical == 0")
		# Confirm follow_focus is off (explicit structural check of the fix).
		_assert_true(not s.follow_focus,
			"[I-A3] ScrollArea.follow_focus == false (follow_focus must be off per #105 fix)")

	for c in root.get_children():
		if c is LoadoutScreen:
			root.remove_child(c)
			c.free()
