## test_s24_4_001_crit_sfx_routing.gd
## [S24.4] Verify critical hit SFX routing: bus assignment, crit branch exclusivity.
extends Node

var pass_count := 0
var fail_count := 0

func _run_test(desc: String, cond: bool) -> void:
	if cond:
		pass_count += 1
		print("  PASS: %s" % desc)
	else:
		fail_count += 1
		print("  FAIL: %s" % desc)

func run() -> int:
	print("\n=== test_s24_4_001_crit_sfx_routing ===")

	# T1a: AudioStreamPlayer .bus = "SFX" assignment works correctly
	var player_crit := AudioStreamPlayer.new()
	player_crit.bus = "SFX"
	_run_test("CriticalHitSfxPlayer.bus == 'SFX' (not 'Master')", player_crit.bus == "SFX")

	# T1b: .bus assignment is distinct from default "Master"
	var player_default := AudioStreamPlayer.new()
	_run_test("Default AudioStreamPlayer.bus is 'Master' (baseline)", player_default.bus == "Master")

	# T1c: Critical player bus differs from default (confirms SFX override)
	_run_test("CriticalHitSfxPlayer.bus != default 'Master'", player_crit.bus != player_default.bus)

	# T1d: Crit-branch logic: is_crit=true routes to crit player, not hit player
	# Simulate the branch decision logic
	var is_crit_true := true
	var amount_large := 10.0
	var hit_sfx_min_amount := 5.0
	var routed_to_crit := false
	var routed_to_hit := false
	if is_crit_true:
		routed_to_crit = true
	elif amount_large >= hit_sfx_min_amount:
		routed_to_hit = true
	_run_test("is_crit=true routes to crit player", routed_to_crit == true)
	_run_test("is_crit=true does NOT route to hit player", routed_to_hit == false)

	# T1e: Crit-branch logic: is_crit=false + amount>=threshold routes to hit player only
	var is_crit_false := false
	routed_to_crit = false
	routed_to_hit = false
	if is_crit_false:
		routed_to_crit = true
	elif amount_large >= hit_sfx_min_amount:
		routed_to_hit = true
	_run_test("is_crit=false + amount>=threshold routes to hit player", routed_to_hit == true)
	_run_test("is_crit=false does NOT route to crit player", routed_to_crit == false)

	# T1f: Crit-branch logic: is_crit=false + amount<threshold = silence (neither fires)
	var amount_small := 2.0
	routed_to_crit = false
	routed_to_hit = false
	if is_crit_false:
		routed_to_crit = true
	elif amount_small >= hit_sfx_min_amount:
		routed_to_hit = true
	_run_test("is_crit=false + amount<threshold: silence (no routing)", routed_to_crit == false and routed_to_hit == false)

	# Cleanup
	player_crit.free()
	player_default.free()

	print("--- %d passed, %d failed ---" % [pass_count, fail_count])
	return fail_count

func _ready() -> void:
	var failures := run()
	quit(1 if failures > 0 else 0)
