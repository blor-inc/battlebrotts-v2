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
	_t11_build_opponent_brott_uses_picker()
	_t12_build_opponent_brott_variety()
	_t13_build_opponent_brott_null_game_state()
	_t14_picker_accepts_player_archetype_hint()

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
		if t["stance"] < 0 or t["stance"] > 3: ok = false
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
		var pick := OpponentLoadouts.pick_opponent_loadout(2, "", last)
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
		var pick := OpponentLoadouts.pick_opponent_loadout(3, "", OpponentLoadouts.Archetype.CONTROLLER)
		if not _is_valid_template(pick):
			assert_true(false, "T9 picker returned invalid template on iter %d" % i)
			return
	assert_true(true, "T9 picker_variety_fallback_when_pool_size_1")

func _t10_difficulty_for_scrapyard() -> void:
	assert_eq(OpponentLoadouts.difficulty_for("scrapyard", 0), 1, "T10a scrapyard[0]=1")
	assert_eq(OpponentLoadouts.difficulty_for("scrapyard", 1), 1, "T10b scrapyard[1]=1")
	assert_eq(OpponentLoadouts.difficulty_for("scrapyard", 2), 2, "T10c scrapyard[2]=2")

## ===== Nutts-B integration tests (11-14) =====

func _template_archetypes_for_tier(tier: int) -> Array:
	var pool: Array = []
	for t in OpponentLoadouts.TEMPLATES:
		if t.tier == tier:
			pool.append(t.archetype)
		elif tier == 1 and t.tier == 0:  # won't happen, tiers start at 1
			pool.append(t.archetype)
	return pool

func _t11_build_opponent_brott_uses_picker() -> void:
	var gs := GameState.new()
	# scrapyard[2] -> tier 2. Call a few times; every result must match a template.
	var all_ok := true
	for i in 5:
		var b: BrottState = OpponentData.build_opponent_brott("scrapyard", 2, gs)
		if b == null:
			all_ok = false
			break
		var matched := false
		for t in OpponentLoadouts.TEMPLATES:
			if t.name == b.bot_name and t.chassis == b.chassis_type and t.armor == b.armor_type and t.stance == b.stance:
				matched = true
				break
		if not matched:
			all_ok = false
			break
	assert_true(all_ok, "T11 build_opponent_brott_uses_picker — brott fields match a template")

func _t12_build_opponent_brott_variety() -> void:
	# S21.1 remediation (Gizmo §6.2b / Optic D4): scrapyard now filters Silver+
	# templates via `unlock_league`, leaving only `tank_tincan` (TANK) in the
	# effective scrapyard pool. Variety is therefore not achievable under
	# scrapyard anymore — the variety invariant now lives on bronze+ pools,
	# which have ≥3 distinct archetypes at tier 2. Re-target this test to
	# bronze[2] (tier 2) to preserve the "no back-to-back archetype" intent.
	var gs := GameState.new()
	var last_arch: int = -1
	var no_repeat := true
	var any_brott := true
	for i in 5:
		var b: BrottState = OpponentData.build_opponent_brott("bronze", 2, gs)
		if b == null:
			any_brott = false
			break
		var arch: int = gs._last_opponent_archetype
		if last_arch != -1 and arch == last_arch:
			no_repeat = false
		last_arch = arch
	assert_true(any_brott, "T12a build_opponent_brott_variety — all builds non-null")
	assert_true(no_repeat, "T12b build_opponent_brott_variety — no back-to-back archetype")

func _t13_build_opponent_brott_null_game_state() -> void:
	# Back-compat: callable without GameState; must still return a valid brott.
	var b: BrottState = OpponentData.build_opponent_brott("scrapyard", 0, null)
	var ok: bool = b != null and b.team == 1 and b.bot_name != "" and b.brain != null
	assert_true(ok, "T13 build_opponent_brott_null_game_state — valid brott, no crash")

func _t14_picker_accepts_player_archetype_hint() -> void:
	# Signature stability: third param (player_archetype_hint) accepted without error.
	var pick: Dictionary = OpponentLoadouts.pick_opponent_loadout(2, "", -1, OpponentLoadouts.Archetype.TANK)
	assert_true(_is_valid_template(pick), "T14 picker_accepts_player_archetype_hint — valid template with hint param")
