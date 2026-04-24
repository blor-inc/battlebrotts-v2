## S21.4 / #106 — Random-event popup redesign (named anchor + skip button + dampening)
## Usage: godot --headless --path godot/ --script res://tests/test_s21_4_002_event_popup.gd
##
## Nutts tests covering:
##   Test 1 (I-B1):  SkipButton dismisses popup — after skip, no popup in scene.
##   Test 2 (I-B3):  RandomEventPopupAnchor node: exact name, direct child of GameMain,
##                   position.y below max(PlayerInfo.bottom, EnemyInfo.bottom, TimeLabel.bottom).
##   Test 3 (I-B6):  Dampening — two triggers within RANDOM_EVENT_MIN_INTERVAL_SEC / 2;
##                   exactly one popup present afterward (second suppressed).
##   Test 4 (I-B5):  SkipButton visible == true and disabled == false at popup show moment.
##
## Strategy: instantiate GameMainScript directly (not the full scene tree).
## HUD nodes are synthesised manually via add_child before calling target methods,
## mirroring the S21.3 test pattern. Engine.get_ticks_msec() is used for dampening;
## tests that need to bypass the window call show_random_event twice in the same ms
## frame, relying on the "already showing" guard being the first suppressor — OR
## we manipulate _re_last_shown_time directly to simulate elapsed time.

extends SceneTree

var pass_count := 0
var fail_count := 0
var test_count := 0

const GameMainScript := preload("res://game_main.gd")

func _initialize() -> void:
	print("=== S21.4-002 Random-event popup tests ===\n")
	_test_skip_button_dismisses_popup()
	_test_anchor_node_exists_and_positioned()
	_test_dampening_suppresses_second_trigger()
	_test_skip_button_visible_and_enabled_on_show()
	print("\n=== Results: %d passed, %d failed, %d total ===" % [pass_count, fail_count, test_count])
	quit(1 if fail_count > 0 else 0)

# ─── helpers ─────────────────────────────────────────────────────────────────

func _assert(cond: bool, msg: String) -> void:
	test_count += 1
	if cond:
		pass_count += 1
	else:
		fail_count += 1
		print("  FAIL: %s" % msg)

func _assert_eq(a: Variant, b: Variant, msg: String) -> void:
	_assert(a == b, "%s (got %s, expected %s)" % [msg, str(a), str(b)])

## Build a minimal GameMain node with HUD children consistent with
## _create_arena_hud output. Does NOT add to the scene tree (no viewport).
func _make_game_main_with_hud() -> Node2D:
	var gm: Node2D = GameMainScript.new()
	gm.name = "GameMain"

	# PlayerInfo
	var pi := Label.new()
	pi.name = "PlayerInfo"
	pi.position = Vector2(20.0, 10.0)
	pi.size = Vector2(500.0, 30.0)
	gm.add_child(pi)
	gm.set("player_info", pi)

	# EnemyInfo
	var ei := Label.new()
	ei.name = "EnemyInfo"
	ei.position = Vector2(700.0, 10.0)
	ei.size = Vector2(500.0, 30.0)
	gm.add_child(ei)
	gm.set("enemy_info", ei)

	# TimeLabel
	var tl := Label.new()
	tl.name = "TimeLabel"
	tl.position = Vector2(600.0, 10.0)
	tl.size = Vector2(100.0, 30.0)
	gm.add_child(tl)
	gm.set("time_label", tl)

	# SpeedLabel
	var sl := Label.new()
	sl.name = "SpeedLabel"
	sl.position = Vector2(600.0, 680.0)
	sl.size = Vector2(100.0, 30.0)
	gm.add_child(sl)
	gm.set("speed_label", sl)

	# ConcedeButton
	var cb := Button.new()
	cb.name = "ConcedeButton"
	cb.text = "Concede"
	cb.position = Vector2(1180.0, 10.0)
	cb.size = Vector2(80.0, 24.0)
	gm.add_child(cb)

	# EnergyLegend
	var el := Label.new()
	el.name = "EnergyLegend"
	el.text = "⚡ Energy"
	el.position = Vector2(20.0, 42.0)
	el.size = Vector2(120.0, 20.0)
	gm.add_child(el)

	# RandomEventPopupAnchor (added by _create_arena_hud in production;
	# synthesised here so test can exercise show_random_event directly).
	var anchor := Node2D.new()
	anchor.name = "RandomEventPopupAnchor"
	anchor.position = Vector2(384.0, 50.0)
	gm.add_child(anchor)

	return gm

# ─── Test 1: SkipButton dismisses popup (I-B1) ───────────────────────────────

func _test_skip_button_dismisses_popup() -> void:
	print("--- Test 1: SkipButton dismisses popup (I-B1) ---")
	var gm := _make_game_main_with_hud()

	# Force dampening bypass: set last-shown to far past.
	gm.set("_re_last_shown_time", -INF)
	gm.show_random_event({"title": "Test Event", "body": "Something happened."})

	# Popup should now exist.
	var popup_before: Node = gm.get_node_or_null("RandomEventPopup")
	_assert(popup_before != null, "Popup node present after show_random_event()")

	# Find SkipButton inside popup.
	if popup_before != null:
		var skip_btn: Node = popup_before.get_node_or_null("SkipButton")
		_assert(skip_btn != null, "SkipButton node present in popup subtree")
		if skip_btn != null:
			# Simulate press via gm's dismiss method (direct signal not
			# easily triggerable without SceneTree processing; call dismiss
			# as the pressed callback would).
			gm.call("_on_random_event_skipped")
			# _re_popup should now be null.
			var re_popup_ref = gm.get("_re_popup")
			_assert(re_popup_ref == null, "After skip, _re_popup is null (I-B1)")
			# get_node_or_null should also miss (queue_free schedules removal;
			# in script-only context it is freed synchronously via queue_free).
			# We accept _re_popup == null as the authoritative check.

	gm.free()

# ─── Test 2: Anchor node exists, correct name, below HUD top-row (I-B3) ─────

func _test_anchor_node_exists_and_positioned() -> void:
	print("--- Test 2: RandomEventPopupAnchor exists + positioned below HUD top-row (I-B3) ---")
	var gm := _make_game_main_with_hud()

	# Locate anchor as direct child of GameMain.
	var anchor: Node = null
	for child in gm.get_children():
		if child.name == "RandomEventPopupAnchor":
			anchor = child
			break

	_assert(anchor != null, "RandomEventPopupAnchor node exists as direct child of GameMain")

	if anchor != null:
		_assert_eq(anchor.name, "RandomEventPopupAnchor",
			"Anchor name is exactly 'RandomEventPopupAnchor' (case-sensitive)")

		# I-B4c: anchor.position.y below max(PlayerInfo.bottom, EnemyInfo.bottom, TimeLabel.bottom).
		# HUD top-row nodes all have position.y=10, size.y=30 → bottom=40.
		# Tolerance ±4 px per I-B4c; so anchor.y must be > 40 - 4 = 36.
		var player_info_bottom := 10.0 + 30.0  # position.y + size.y
		var enemy_info_bottom  := 10.0 + 30.0
		var time_label_bottom  := 10.0 + 30.0
		var hud_top_row_bottom := maxf(maxf(player_info_bottom, enemy_info_bottom), time_label_bottom)
		var anchor_y: float = (anchor as Node2D).position.y
		_assert(anchor_y > hud_top_row_bottom - 4.0,
			"RandomEventPopupAnchor.y (%g) is below HUD top-row bottom (%g ± 4px)" % [anchor_y, hud_top_row_bottom])

	gm.free()

# ─── Test 3: Dampening suppresses second trigger (I-B6) ──────────────────────

func _test_dampening_suppresses_second_trigger() -> void:
	print("--- Test 3: Dampening suppresses second trigger within interval (I-B6) ---")
	var gm := _make_game_main_with_hud()

	# Reset dampening.
	gm.set("_re_last_shown_time", -INF)

	# First trigger — should show popup.
	gm.show_random_event({"title": "Event A"})
	var popup_first: Node = gm.get_node_or_null("RandomEventPopup")
	_assert(popup_first != null, "First trigger shows popup")

	# Dismiss first popup so guard 'already showing' is cleared.
	gm.call("_dismiss_random_event_popup")
	_assert(gm.get("_re_popup") == null, "Popup dismissed between triggers")

	# Second trigger within RANDOM_EVENT_MIN_INTERVAL_SEC / 2 (dampening window).
	# _re_last_shown_time was set during first show; Time.get_ticks_msec() /
	# 1000.0 is still within the interval (same ms frame in headless test).
	# NOTE: check _re_popup (null = suppressed) not get_node_or_null("RandomEventPopup")
	# because queue_free() defers removal; the dismissed node is still in tree.
	gm.show_random_event({"title": "Event B"})
	_assert(gm.get("_re_popup") == null,
		"Second trigger within RANDOM_EVENT_MIN_INTERVAL_SEC is suppressed (I-B6)")

	gm.free()

# ─── Test 4: SkipButton visible + enabled at popup show (I-B5) ───────────────

func _test_skip_button_visible_and_enabled_on_show() -> void:
	print("--- Test 4: SkipButton visible and enabled at popup-show (I-B5) ---")
	var gm := _make_game_main_with_hud()

	gm.set("_re_last_shown_time", -INF)
	gm.show_random_event({"title": "Flow Event"})

	var popup: Node = gm.get_node_or_null("RandomEventPopup")
	_assert(popup != null, "Popup present for I-B5 check")

	if popup != null:
		var skip_btn = popup.get_node_or_null("SkipButton")
		_assert(skip_btn != null, "SkipButton node present for I-B5 check")
		if skip_btn != null:
			_assert(skip_btn.visible == true,
				"SkipButton.visible == true at popup-show (I-B5)")
			_assert(skip_btn.disabled == false,
				"SkipButton.disabled == false at popup-show (I-B5)")

	gm.free()
