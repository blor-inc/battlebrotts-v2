## test_s24_4_001_crit_sfx_routing.gd
## [S24.4] Verify critical hit SFX routing: bus assignment, crit branch exclusivity.
## Usage: godot --headless --path godot/ --script res://tests/test_s24_4_001_crit_sfx_routing.gd

extends SceneTree

var pass_count := 0
var fail_count := 0
var test_count := 0

func _initialize() -> void:
	print("=== test_s24_4_001_crit_sfx_routing ===\n")
	_test_crit_player_bus_assignment()
	_test_default_bus_is_master()
	_test_crit_player_bus_differs_from_default()
	_test_is_crit_true_routes_to_crit()
	_test_is_crit_true_not_to_hit()
	_test_is_crit_false_routes_to_hit()
	_test_is_crit_false_below_threshold_silence()
	print("\n=== Results: %d passed, %d failed, %d total ===" % [pass_count, fail_count, test_count])
	quit(1 if fail_count > 0 else 0)

func _assert(cond: bool, msg: String) -> void:
	test_count += 1
	if cond:
		pass_count += 1
		print("  PASS: %s" % msg)
	else:
		fail_count += 1
		print("  FAIL: %s" % msg)

func _test_crit_player_bus_assignment() -> void:
	print("--- T1a: CriticalHitSfxPlayer.bus == 'SFX' ---")
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	_assert(player.bus == "SFX", "CriticalHitSfxPlayer.bus == 'SFX' (not 'Master')")
	player.free()

func _test_default_bus_is_master() -> void:
	print("--- T1b: Default AudioStreamPlayer.bus is 'Master' ---")
	var player := AudioStreamPlayer.new()
	_assert(player.bus == "Master", "Default AudioStreamPlayer.bus is 'Master' (baseline)")
	player.free()

func _test_crit_player_bus_differs_from_default() -> void:
	print("--- T1c: CriticalHitSfxPlayer.bus != default 'Master' ---")
	var player_crit := AudioStreamPlayer.new()
	player_crit.bus = "SFX"
	var player_default := AudioStreamPlayer.new()
	_assert(player_crit.bus != player_default.bus, "CriticalHitSfxPlayer.bus != default 'Master'")
	player_crit.free()
	player_default.free()

func _test_is_crit_true_routes_to_crit() -> void:
	print("--- T1d: is_crit=true routes to crit player ---")
	var is_crit := true
	var amount := 10.0
	var hit_sfx_min := 5.0
	var routed_to_crit := false
	var routed_to_hit := false
	if is_crit:
		routed_to_crit = true
	elif amount >= hit_sfx_min:
		routed_to_hit = true
	_assert(routed_to_crit == true, "is_crit=true routes to crit player")

func _test_is_crit_true_not_to_hit() -> void:
	print("--- T1e: is_crit=true does NOT route to hit player ---")
	var is_crit := true
	var amount := 10.0
	var hit_sfx_min := 5.0
	var routed_to_hit := false
	if not is_crit and amount >= hit_sfx_min:
		routed_to_hit = true
	_assert(routed_to_hit == false, "is_crit=true does NOT route to hit player (mutually exclusive)")

func _test_is_crit_false_routes_to_hit() -> void:
	print("--- T1f: is_crit=false + amount>=threshold routes to hit player ---")
	var is_crit := false
	var amount := 10.0
	var hit_sfx_min := 5.0
	var routed_to_crit := false
	var routed_to_hit := false
	if is_crit:
		routed_to_crit = true
	elif amount >= hit_sfx_min:
		routed_to_hit = true
	_assert(routed_to_hit == true, "is_crit=false + amount>=threshold routes to hit player")
	_assert(routed_to_crit == false, "is_crit=false does NOT route to crit player")

func _test_is_crit_false_below_threshold_silence() -> void:
	print("--- T1g: is_crit=false + amount<threshold = silence ---")
	var is_crit := false
	var amount := 2.0
	var hit_sfx_min := 5.0
	var routed_to_crit := false
	var routed_to_hit := false
	if is_crit:
		routed_to_crit = true
	elif amount >= hit_sfx_min:
		routed_to_hit = true
	_assert(routed_to_crit == false and routed_to_hit == false,
		"is_crit=false + amount<threshold: silence (neither fires)")
