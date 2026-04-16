## Sprint 13.9 — Opponent loadout template + picker tests (Nutts-A, tests 1-10).
## Usage: godot --headless --script tests/test_sprint13_9.gd
## Spec: docs/design/sprint13.9-fortress-loadout-pass.md §7.
## Tests 11-14 (build_opponent_brott integration + counter-play hook) are Nutts-B's scope.
extends SceneTree

var pass_count := 0
var fail_count := 0
var test_count := 0

func _initialize() -> void:
	print("=== Sprint 13.9 Opponent Loadouts Tests (Nutts-A) ===\n")
	_run_all()
	print("\n=== Results: %d passed, %d failed, %d total ===" % [pass_count, fail_count, test_count])
	quit(1 if fail_count > 0 else 0)

func assert_true(cond: bool, msg: String) -> void:
	test_count += 1
	if cond:
		pass_count += 1
	else:
		fail_count += 1
		print("  FAIL: %s" % msg)

func assert_eq(a, b, msg: String) -> void:
	test_count += 1
	if a == b:
		pass_count += 1
	else:
		fail_count += 1
		print("  FAIL: %s (got %s, expected %s)" % [msg, str(a), str(b)])

func _run_all() -> void:
	_t1_templates_list_nonempty()
	_t2_templates_use_valid_enums()
	_t3_templates_respect_slot_limits()
	_t4_templates_archetypes_cover_min_four()
	_t5_templates_tiers_span_range()
	_t6_picker_returns_valid_template_tier1()
	_t7_picker_returns_valid_template_tier3()
	_t8_picker_variety_10_picks()
	_t9_picker_variety_fallback_when_pool_size_1()
	_t10_difficulty_for_scrapyard()

func _is_valid_template(t: Dictionary) -> bool:
	for k in ["id", "name", "archetype", "tier", "chassis", "weapons", "armor", "modules", "stance"]:
		if not t.has(k):
			return false
	return true

func _t1_templates_list_nonempty() -> void:
	assert_true(OpponentLoadouts.TEMPLATES.size() >= 4, "T1 templates_list_nonempty (≥4)")

func _t2_templates_use_valid_enums() -> void:
	var ok := true
	for t in OpponentLoadouts.TEMPLATES:
		if not ChassisData.CHASSIS.has(t["chassis"]): ok = false
		if not ArmorData.ARMORS.has(t["armor"]): ok = false
		for w in t["weapons"]:
			if not WeaponData.WEAPONS.has(w): ok = false
		for m in t["modules"]:
			if not ModuleData.MODULES.has(m): ok = false
		if t["stance"] < 0 or t["stance"] > 2: ok = false
	assert_true(ok, "T2 templates_use_valid_enums")

func _t3_templates_respect_slot_limits() -> void:
	var ok := true
	for t in OpponentLoadouts.TEMPLATES:
		var c: Dictionary = ChassisData.CHASSIS[t["chassis"]]
		if t["weapons"].size() > c["weapon_slots"]: ok = false
		if t["modules"].size() > c["module_slots"]: ok = false
	assert_true(ok, "T3 templates_respect_slot_limits")

func _t4_templates_archetypes_cover_min_four() -> void:
	var seen := {}
	for t in OpponentLoadouts.TEMPLATES:
		seen[t["archetype"]] = true
	assert_true(seen.size() >= 4, "T4 templates_archetypes_cover_min_four (got %d)" % seen.size())

func _t5_templates_tiers_span_range() -> void:
	var tiers := {}
	for t in OpponentLoadouts.TEMPLATES:
		tiers[t["tier"]] = true
	assert_true(tiers.has(1) and tiers.has(2) and tiers.has(3), "T5 templates_tiers_span_range")

func _t6_picker_returns_valid_template_tier1() -> void:
	var pick := OpponentLoadouts.pick_opponent_loadout(1)
	assert_true(_is_valid_template(pick), "T6 picker_returns_valid_template_tier1")

func _t7_picker_returns_valid_template_tier3() -> void:
	var pick := OpponentLoadouts.pick_opponent_loadout(3)
	assert_true(_is_valid_template(pick), "T7 picker_returns_valid_template_tier3")

func _t8_picker_variety_10_picks() -> void:
	var last := -1
	var no_repeat := true
	for i in 10:
		var pick := OpponentLoadouts.pick_opponent_loadout(2, last)
		if last != -1 and pick["archetype"] == last:
			no_repeat = false
		last = pick["archetype"]
	assert_true(no_repeat, "T8 picker_variety_10_picks (no back-to-back)")

func _t9_picker_variety_fallback_when_pool_size_1() -> void:
	# Tier 3 has exactly one template (CONTROLLER/Jammer). With fallback, tier-2 joins the pool
	# when pool<2, but if we pre-poison the variety strip to remove everything, picker must
	# still return a non-empty dict. Repeatedly call with last_archetype=CONTROLLER; picker
	# should not crash and should return a valid template (either the controller itself via
	# "keep pool when strip empties" OR a tier-2 fallback).
	for i in 20:
		var pick := OpponentLoadouts.pick_opponent_loadout(3, OpponentLoadouts.Archetype.CONTROLLER)
		if not _is_valid_template(pick):
			assert_true(false, "T9 picker returned invalid template on iter %d" % i)
			return
	assert_true(true, "T9 picker_variety_fallback_when_pool_size_1")

func _t10_difficulty_for_scrapyard() -> void:
	assert_eq(OpponentLoadouts.difficulty_for("scrapyard", 0), 1, "T10a scrapyard[0]=1")
	assert_eq(OpponentLoadouts.difficulty_for("scrapyard", 1), 1, "T10b scrapyard[1]=1")
	assert_eq(OpponentLoadouts.difficulty_for("scrapyard", 2), 2, "T10c scrapyard[2]=2")
