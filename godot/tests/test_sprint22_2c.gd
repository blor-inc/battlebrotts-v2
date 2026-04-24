## S22.2c unit tests — per-league reflect-damage lever.
## 6 tests, 8 assertions per Gizmo §A.2.
## Register in test_runner.gd::SPRINT_TEST_FILES.
extends SceneTree

var pass_count := 0
var fail_count := 0


func _initialize() -> void:
	print("--- S22.2c unit tests ---")
	_test_reflect_bronze()
	_test_reflect_silver()
	_test_reflect_non_mesh()
	_test_reflect_unknown_league_fallback()
	_test_reflect_scrapyard_equals_bronze()
	_test_reflect_degrades_monotonically_by_league()
	print("S22.2c unit tests: %d passed, %d failed" % [pass_count, fail_count])
	if fail_count > 0:
		print("S22.2c FAIL")
	else:
		print("S22.2c PASS")
	quit(1 if fail_count > 0 else 0)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		pass_count += 1
		print("  PASS: %s" % msg)
	else:
		fail_count += 1
		print("  FAIL: %s" % msg)


# T1: Bronze reflect == 5.0 (canonical; MUST NOT CHANGE)
func _test_reflect_bronze() -> void:
	var val := ArmorData.reflect_damage_for_league(ArmorData.ArmorType.REACTIVE_MESH, "bronze")
	_assert(val == 5.0, "T1: bronze reflect == 5.0 (got %s)" % val)


# T2: Silver reflect == 2.0
func _test_reflect_silver() -> void:
	var val := ArmorData.reflect_damage_for_league(ArmorData.ArmorType.REACTIVE_MESH, "silver")
	_assert(val == 2.0, "T2: silver reflect == 2.0 (got %s)" % val)


# T3: Non-reflect armor returns 0.0 regardless of league (2 assertions)
func _test_reflect_non_mesh() -> void:
	var val_silver := ArmorData.reflect_damage_for_league(ArmorData.ArmorType.PLATING, "silver")
	_assert(val_silver == 0.0, "T3a: PLATING at silver returns 0.0 (got %s)" % val_silver)
	var val_bronze := ArmorData.reflect_damage_for_league(ArmorData.ArmorType.NONE, "bronze")
	_assert(val_bronze == 0.0, "T3b: NONE at bronze returns 0.0 (got %s)" % val_bronze)


# T4: Unknown league falls back to bronze value (5.0)
func _test_reflect_unknown_league_fallback() -> void:
	var val := ArmorData.reflect_damage_for_league(ArmorData.ArmorType.REACTIVE_MESH, "diamond")
	_assert(val == 5.0, "T4: unknown league 'diamond' fallback == 5.0 (got %s)" % val)


# T5: Scrapyard reflect == bronze reflect (both 5.0; shared floor)
func _test_reflect_scrapyard_equals_bronze() -> void:
	var bronze_val := ArmorData.reflect_damage_for_league(ArmorData.ArmorType.REACTIVE_MESH, "bronze")
	var scrap_val := ArmorData.reflect_damage_for_league(ArmorData.ArmorType.REACTIVE_MESH, "scrapyard")
	_assert(bronze_val == scrap_val,
		"T5: scrapyard (%s) == bronze (%s)" % [scrap_val, bronze_val])


# T6: reflect damage is strictly decreasing bronze → silver, and
# no higher league exceeds bronze. Data-contract proof of asymmetric
# league-degradation (replaces combat-loop proxy; see §A.2 note —
# combat-loop variant hit death-before-differentiate under MINIGUN fixture).
func _test_reflect_degrades_monotonically_by_league() -> void:
	var bronze: float = ArmorData.reflect_damage_for_league(ArmorData.ArmorType.REACTIVE_MESH, "bronze")
	var silver: float = ArmorData.reflect_damage_for_league(ArmorData.ArmorType.REACTIVE_MESH, "silver")
	_assert(silver < bronze,
		"T6a fail: silver reflect (%s) must be < bronze reflect (%s)" % [silver, bronze])
	for league in ["silver", "gold", "platinum"]:
		var val: float = ArmorData.reflect_damage_for_league(ArmorData.ArmorType.REACTIVE_MESH, league)
		_assert(val <= bronze,
			"T6b fail: %s reflect (%s) must be <= bronze reflect (%s)" % [league, val, bronze])
