## Sprint 13.8 — Item-name toast substitution (Nutts-B)
## Usage: godot --headless --script tests/test_sprint13_8_toast.gd
##
## Covers S13.8 §3 item 5 + ACs 5.1, 5.2. Exercises ShopScreen's
## _prepare_trick_for_modal / _substitute_item_name helpers via a headless
## ShopScreen instance (no scene tree beyond a dummy parent).
extends SceneTree

var pass_count := 0
var fail_count := 0
var test_count := 0

const ShopScreenScript := preload("res://ui/shop_screen.gd")

func _initialize() -> void:
	print("=== Sprint 13.8 Item-Name Toast Tests (Nutts-B) ===\n")
	randomize()
	_run_all()
	print("\n=== Results: %d passed, %d failed, %d total ===" % [pass_count, fail_count, test_count])
	if fail_count > 0:
		quit(1)
	else:
		quit(0)

func assert_eq(a, b, msg: String) -> void:
	test_count += 1
	if a == b:
		pass_count += 1
	else:
		fail_count += 1
		print("  FAIL: %s (got %s, expected %s)" % [msg, str(a), str(b)])

func assert_true(cond: bool, msg: String) -> void:
	test_count += 1
	if cond:
		pass_count += 1
	else:
		fail_count += 1
		print("  FAIL: %s" % msg)

func _make_shop() -> ShopScreen:
	var s: ShopScreen = ShopScreenScript.new()
	# Attach to the scene tree so the script is fully initialised.
	get_root().add_child(s)
	return s

func _cleanup(s: ShopScreen) -> void:
	get_root().remove_child(s)
	s.queue_free()

# --- Tests ---

func _run_all() -> void:
	_test_no_placeholder_unchanged()
	_test_non_item_effect_unchanged()
	_test_item_grant_direct_token()
	_test_item_grant_pool_token_rewrites_concrete()
	_test_effect_value_2_item()
	_test_show_trick_receives_substituted()

func _test_no_placeholder_unchanged() -> void:
	var s := _make_shop()
	var choice := {
		"effect_type": TrickChoices.EffectType.ITEM_GRANT,
		"effect_value": "minigun",
	}
	var out: String = s._substitute_item_name("Smart. +10 bolts.", choice)
	assert_eq(out, "Smart. +10 bolts.", "no-placeholder string returned unchanged")
	_cleanup(s)

func _test_non_item_effect_unchanged() -> void:
	var s := _make_shop()
	var choice := {
		"effect_type": TrickChoices.EffectType.BOLTS_DELTA,
		"effect_value": 10,
	}
	var out: String = s._substitute_item_name("Picked up a {item_name}.", choice)
	# Placeholder intact (AC5.2): QA catches authoring mistakes.
	assert_eq(out, "Picked up a {item_name}.", "non-item effect leaves placeholder intact")
	_cleanup(s)

func _test_item_grant_direct_token() -> void:
	var s := _make_shop()
	var choice := {
		"effect_type": TrickChoices.EffectType.ITEM_GRANT,
		"effect_value": "minigun",
	}
	var out: String = s._substitute_item_name("Nice. Found a {item_name}.", choice)
	var expected_name: String = String(WeaponData.WEAPONS[WeaponData.WeaponType.MINIGUN]["name"])
	assert_eq(out, "Nice. Found a %s." % expected_name, "direct token substituted with display name")
	_cleanup(s)

func _test_item_grant_pool_token_rewrites_concrete() -> void:
	# After _prepare_trick_for_modal, pool tokens are replaced by concrete
	# direct tokens so apply_trick_choice's re-resolve hits the DIRECT table
	# and returns the same item. We assert (a) the rewrite happened, (b) the
	# flavor_line substitution matches the concrete token's display name.
	var s := _make_shop()
	var trick := {
		"id": "crate_find",
		"choice_a": {
			"label": "Crack it",
			"effect_type": TrickChoices.EffectType.ITEM_GRANT,
			"effect_value": "random_weak",
			"flavor_line": "Nice. Found a {item_name}.",
		},
		"choice_b": {
			"label": "Walk past",
			"effect_type": TrickChoices.EffectType.BOLTS_DELTA,
			"effect_value": 0,
			"flavor_line": "Smart. Rats.",
		},
	}
	var patched: Dictionary = s._prepare_trick_for_modal(trick)
	var new_tok: String = String(patched["choice_a"]["effect_value"])
	assert_true(new_tok != "random_weak", "pool token rewritten to concrete direct token")
	assert_true(ItemTokens.DIRECT.has(new_tok), "rewritten token is in DIRECT table")
	# Flavor line should reference the concrete item's display name.
	var resolved: Dictionary = ItemTokens.resolve_token(new_tok)
	var name: String = ItemTokens.display_name(resolved)
	assert_eq(patched["choice_a"]["flavor_line"], "Nice. Found a %s." % name, "flavor_line uses concrete item name")
	# Original trick must be untouched (deep-duplicate guard).
	assert_eq(String(trick["choice_a"]["effect_value"]), "random_weak", "original trick not mutated")
	_cleanup(s)

func _test_effect_value_2_item() -> void:
	# scrap_trader has BOLTS_DELTA as primary and ITEM_GRANT as secondary —
	# _substitute_item_name must look at effect_value_2.
	var s := _make_shop()
	var choice := {
		"effect_type": TrickChoices.EffectType.BOLTS_DELTA,
		"effect_value": -15,
		"effect_type_2": TrickChoices.EffectType.ITEM_GRANT,
		"effect_value_2": "overclock",
	}
	var out: String = s._substitute_item_name("Installed a {item_name}.", choice)
	var expected_name: String = String(ModuleData.MODULES[ModuleData.ModuleType.OVERCLOCK]["name"])
	assert_eq(out, "Installed a %s." % expected_name, "effect_value_2 item token substituted")
	_cleanup(s)

func _test_show_trick_receives_substituted() -> void:
	# Assert the patched dict passed to modal.show_trick has no {item_name}
	# placeholder left in any ITEM_GRANT/LOSE flavor_line after preparation.
	var s := _make_shop()
	for trick in TrickChoices.TRICKS:
		var patched: Dictionary = s._prepare_trick_for_modal(trick)
		for key in ["choice_a", "choice_b"]:
			var c: Dictionary = patched[key]
			var et = c.get("effect_type")
			var et2 = c.get("effect_type_2")
			var has_item = (
				et == TrickChoices.EffectType.ITEM_GRANT
				or et == TrickChoices.EffectType.ITEM_LOSE
				or et2 == TrickChoices.EffectType.ITEM_GRANT
				or et2 == TrickChoices.EffectType.ITEM_LOSE
			)
			if has_item:
				var fl: String = String(c.get("flavor_line", ""))
				assert_true(not ("{item_name}" in fl),
					"trick=%s %s: placeholder substituted (got %s)" % [trick.get("id", "?"), key, fl])
	_cleanup(s)
