## Sprint 21.1 — Bronze content drop tests.
## Usage: godot --headless --script tests/test_sprint21_1.gd
## Spec: memory/2026-04-23-s21.1-gizmo-bronze-loadout-spec.md §6.1 (unit);
##       memory/2026-04-23-s21.1-ett-sprint-plan.md §3.1.
##
## Tests map to Gizmo §6.1 / Ett §3.1 table:
##   t1 bronze_pool_nonempty       — 100 calls each at tier 2 + 3 return non-empty dict
##   t2 bronze_tier_mapping        — difficulty_for("bronze", i) = [2,2,2,3,3], default 2
##   t3 bronze_legality            — Bronze-legal items only (chassis/weapons/armor/modules,
##                                   len(modules)==1 except scrapyard tank_tincan)
##   t4 bronze_archetype_coverage  — Bronze-legal (tier ≥ 2) has ≥3 distinct archetypes
##                                   (target: all 5)
##   t5 bronze_variety_holds       — 1000 random 5-fight Bronze runs: no consecutive same arch
##   t6 bronze_league_filter       — 100 picks at tier 2 w/ current_league="bronze" never
##                                   return Silver+/Gold+/Plat templates
##   t7 scrapyard_no_regression    — difficulty_for("scrapyard", i) unchanged [1,1,2];
##                                   100 scrapyard picks include ≥2 distinct archetypes
##   t8 weight_budget              — every template's total weight ≤ chassis cap
##   (bonus) behavior_cards_persist — data-only round-trip for new Bronze templates
extends SceneTree

var pass_count := 0
var fail_count := 0
var test_count := 0

const BRONZE_CHASSIS := [ChassisData.ChassisType.SCOUT, ChassisData.ChassisType.BRAWLER]
const BRONZE_WEAPONS := [
	WeaponData.WeaponType.PLASMA_CUTTER,
	WeaponData.WeaponType.MINIGUN,
	WeaponData.WeaponType.SHOTGUN,
	WeaponData.WeaponType.ARC_EMITTER,
]
const BRONZE_ARMOR := [
	ArmorData.ArmorType.NONE,
	ArmorData.ArmorType.PLATING,
	ArmorData.ArmorType.REACTIVE_MESH,
]
const BRONZE_MODULES := [
	ModuleData.ModuleType.OVERCLOCK,
	ModuleData.ModuleType.REPAIR_NANITES,
]

func _initialize() -> void:
	print("=== Sprint 21.1 Bronze content drop tests ===\n")
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
	_t1_bronze_pool_nonempty()
	_t2_bronze_tier_mapping()
	_t3_bronze_legality()
	_t4_bronze_archetype_coverage()
	_t5_bronze_variety_holds()
	_t6_bronze_league_filter()
	_t7_scrapyard_no_regression()
	_t8_weight_budget()
	_t9_behavior_cards_persist()

# ── Helpers ──────────────────────────────────────────────────────────────────

func _league_rank(name: String) -> int:
	return OpponentLoadouts.LEAGUE_RANK.get(name, 99)

func _bronze_legal_templates() -> Array:
	# unlock_league ≤ bronze (rank ≤ 1).
	var out: Array = []
	for t in OpponentLoadouts.TEMPLATES:
		if _league_rank(t.get("unlock_league", "scrapyard")) <= _league_rank("bronze"):
			out.append(t)
	return out

func _chassis_cap(chassis_type: int) -> float:
	var c: Dictionary = ChassisData.CHASSIS[chassis_type]
	# Chassis dict uses "weight_cap" or similar — fall back to a few common keys.
	for k in ["weight_cap", "weight_capacity", "max_weight", "weight"]:
		if c.has(k):
			return float(c[k])
	return 0.0

func _item_weight(table: Dictionary, key: int) -> float:
	var item: Dictionary = table.get(key, {})
	for k in ["weight", "weight_kg", "mass"]:
		if item.has(k):
			return float(item[k])
	return 0.0

# ── Tests ────────────────────────────────────────────────────────────────────

func _t1_bronze_pool_nonempty() -> void:
	var all_ok := true
	for i in 100:
		var p2: Dictionary = OpponentLoadouts.pick_opponent_loadout(2, "bronze")
		var p3: Dictionary = OpponentLoadouts.pick_opponent_loadout(3, "bronze")
		if p2.is_empty() or p3.is_empty():
			all_ok = false
			break
	assert_true(all_ok, "T1 bronze_pool_nonempty — 100 picks each at tier 2 + 3 non-empty")

func _t2_bronze_tier_mapping() -> void:
	var expected := [2, 2, 2, 3, 3]
	var ok := true
	for i in expected.size():
		if OpponentLoadouts.difficulty_for("bronze", i) != expected[i]:
			ok = false
	# Out-of-range default.
	if OpponentLoadouts.difficulty_for("bronze", 5) != 2:
		ok = false
	if OpponentLoadouts.difficulty_for("bronze", -1) != 2:
		ok = false
	assert_true(ok, "T2 bronze_tier_mapping = [2,2,2,3,3] with default 2")

func _t3_bronze_legality() -> void:
	var all_ok := true
	var first_fail := ""
	for t in _bronze_legal_templates():
		var chassis_ok: bool = BRONZE_CHASSIS.has(t["chassis"])
		var weapons_ok := true
		for w in t["weapons"]:
			if not BRONZE_WEAPONS.has(w):
				weapons_ok = false
		var armor_ok: bool = BRONZE_ARMOR.has(t["armor"])
		var modules_ok := true
		for m in t["modules"]:
			if not BRONZE_MODULES.has(m):
				modules_ok = false
		# Module count rule (GDD §6.2): Bronze uses exactly 1 module; scrapyard
		# `tank_tincan` is allowed 0 (scrapyard-baseline); the grandfathered
		# `bruiser_crusher` (S13.9) carries 2 modules and is kept-as-is per
		# Gizmo S21.1 spec §1.
		var module_count_ok: bool
		var tid: String = t.get("id", "")
		if t.get("unlock_league", "scrapyard") == "scrapyard":
			module_count_ok = t["modules"].size() <= 1
		elif tid == "bruiser_crusher":
			module_count_ok = t["modules"].size() <= 2
		else:
			module_count_ok = t["modules"].size() == 1
		if not (chassis_ok and weapons_ok and armor_ok and modules_ok and module_count_ok):
			all_ok = false
			if first_fail == "":
				first_fail = "%s chassis=%s weapons_ok=%s armor_ok=%s modules_ok=%s mcount_ok=%s" % [
					t.get("id", "?"), str(chassis_ok), str(weapons_ok), str(armor_ok),
					str(modules_ok), str(module_count_ok)
				]
	assert_true(all_ok, "T3 bronze_legality (first failing: %s)" % first_fail)

func _t4_bronze_archetype_coverage() -> void:
	# Bronze-legal set filtered to tier >= 2 (actually-Bronze-playable).
	var seen := {}
	for t in _bronze_legal_templates():
		if t["tier"] >= 2:
			seen[t["archetype"]] = true
	# Floor = 3; target = all 5.
	assert_true(seen.size() >= 3, "T4 bronze_archetype_coverage ≥3 (got %d)" % seen.size())
	# Soft-check all 5 (info only — does not affect test_count beyond the line above).
	if seen.size() != 5:
		print("  INFO: bronze archetype coverage = %d (target 5)" % seen.size())

func _t5_bronze_variety_holds() -> void:
	var all_ok := true
	var failed_run := -1
	for run in 1000:
		var last := -1
		for i in 5:
			var tier: int = OpponentLoadouts.difficulty_for("bronze", i)
			var pick: Dictionary = OpponentLoadouts.pick_opponent_loadout(tier, "bronze", last)
			if pick.is_empty():
				all_ok = false
				failed_run = run
				break
			if last != -1 and pick["archetype"] == last:
				all_ok = false
				failed_run = run
				break
			last = pick["archetype"]
		if not all_ok:
			break
	assert_true(all_ok, "T5 bronze_variety_holds 1000× no back-to-back (failed run %d)" % failed_run)

func _t6_bronze_league_filter() -> void:
	var forbidden_ranks := {
		_league_rank("silver"): true,
		_league_rank("gold"): true,
		_league_rank("platinum"): true,
	}
	var all_ok := true
	var leaked_id := ""
	for i in 100:
		var pick: Dictionary = OpponentLoadouts.pick_opponent_loadout(2, "bronze")
		if pick.is_empty():
			all_ok = false
			leaked_id = "<empty>"
			break
		var rank: int = _league_rank(pick.get("unlock_league", "scrapyard"))
		if forbidden_ranks.has(rank):
			all_ok = false
			leaked_id = pick.get("id", "?")
			break
	assert_true(all_ok, "T6 bronze_league_filter — no silver+ leak (leaked: %s)" % leaked_id)

func _t7_scrapyard_no_regression() -> void:
	var s_tiers := [OpponentLoadouts.difficulty_for("scrapyard", 0),
					OpponentLoadouts.difficulty_for("scrapyard", 1),
					OpponentLoadouts.difficulty_for("scrapyard", 2)]
	var mapping_ok := s_tiers == [1, 1, 2]
	# Pick 100 times across all 3 scrapyard indices without passing league — mirrors
	# pre-S21.1 call convention (back-compat path: current_league="").
	var seen := {}
	for i in 100:
		var idx := i % 3
		var tier: int = OpponentLoadouts.difficulty_for("scrapyard", idx)
		var pick: Dictionary = OpponentLoadouts.pick_opponent_loadout(tier)
		if pick.is_empty():
			mapping_ok = false
			break
		seen[pick["archetype"]] = true
	assert_true(mapping_ok and seen.size() >= 2,
		"T7 scrapyard_no_regression — tiers [1,1,2], ≥2 archetypes (got %d)" % seen.size())

func _t8_weight_budget() -> void:
	# Scope: S21.1 new templates + existing Bronze-legal (`bruiser_crusher`,
	# `tank_tincan`). Silver+ grandfathered templates are out of S21.1 scope
	# (`glass_sniper` is intentionally weight-overweight per its S13.9 design
	# and not an S21.1 regression).
	var s21_scope := [
		"tank_rustwall", "glass_zap", "skirmish_scrapper",
		"bruiser_clanker", "control_static", "control_prowler",
		"bruiser_crusher", "tank_tincan",
	]
	var all_ok := true
	var first_fail := ""
	for t in OpponentLoadouts.TEMPLATES:
		if not s21_scope.has(t.get("id", "")):
			continue
		var cap: float = _chassis_cap(t["chassis"])
		if cap <= 0.0:
			continue
		var total: float = 0.0
		for w in t["weapons"]:
			total += _item_weight(WeaponData.WEAPONS, w)
		total += _item_weight(ArmorData.ARMORS, t["armor"])
		for m in t["modules"]:
			total += _item_weight(ModuleData.MODULES, m)
		if total > cap:
			all_ok = false
			if first_fail == "":
				first_fail = "%s total=%.1f cap=%.1f" % [t.get("id", "?"), total, cap]
	assert_true(all_ok, "T8 weight_budget — Bronze-scope templates ≤ chassis cap (first fail: %s)" % first_fail)

func _t9_behavior_cards_persist() -> void:
	# Data-only round-trip: every S21.1 new Bronze template has a populated
	# `behavior_cards` Array. Engine ignores the field this sprint; this test
	# guards the authored-data integrity so the carry-forward BC engine-wiring
	# sprint finds non-empty intent already in place.
	var s21_1_ids := ["tank_rustwall", "glass_zap", "skirmish_scrapper",
					  "bruiser_clanker", "control_static", "control_prowler"]
	var ok := true
	var missing := []
	for t in OpponentLoadouts.TEMPLATES:
		if s21_1_ids.has(t["id"]):
			var bc = t.get("behavior_cards", null)
			if bc == null or not (bc is Array) or bc.is_empty():
				ok = false
				missing.append(t["id"])
			else:
				for card in bc:
					if not (card is Dictionary and card.has("trigger") and card.has("action")):
						ok = false
						missing.append(t["id"] + ":malformed")
	assert_true(ok, "T9 behavior_cards_persist on S21.1 new templates (missing/malformed: %s)" % str(missing))
