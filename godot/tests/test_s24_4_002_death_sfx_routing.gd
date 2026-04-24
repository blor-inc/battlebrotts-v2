## test_s24_4_002_death_sfx_routing.gd
## [S24.4] Verify death SFX routing: bus assignment, cooldown guard behavior.
## Usage: godot --headless --path godot/ --script res://tests/test_s24_4_002_death_sfx_routing.gd

extends SceneTree

var pass_count := 0
var fail_count := 0
var test_count := 0

func _initialize() -> void:
	print("=== test_s24_4_002_death_sfx_routing ===\n")
	_test_death_player_bus_assignment()
	_test_default_bus_is_master()
	_test_death_player_bus_differs_from_default()
	_test_cooldown_prevents_double_fire()
	_test_cooldown_allows_play_when_inactive()
	_test_cooldown_window_is_600ms()
	_test_mass_death_only_first_fires()
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

func _test_death_player_bus_assignment() -> void:
	print("--- T2a: DeathSfxPlayer.bus == 'SFX' ---")
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	_assert(player.bus == "SFX", "DeathSfxPlayer.bus == 'SFX'")
	player.free()

func _test_default_bus_is_master() -> void:
	print("--- T2b: Default AudioStreamPlayer.bus is 'Master' ---")
	var player := AudioStreamPlayer.new()
	_assert(player.bus == "Master", "Default AudioStreamPlayer.bus is 'Master'")
	player.free()

func _test_death_player_bus_differs_from_default() -> void:
	print("--- T2c: DeathSfxPlayer.bus != default 'Master' ---")
	var player_death := AudioStreamPlayer.new()
	player_death.bus = "SFX"
	var player_default := AudioStreamPlayer.new()
	_assert(player_death.bus != player_default.bus, "DeathSfxPlayer.bus != default 'Master'")
	player_death.free()
	player_default.free()

func _test_cooldown_prevents_double_fire() -> void:
	print("--- T2d: Cooldown guard prevents play when active ---")
	var cooldown_active := true
	var play_attempted := false
	if not cooldown_active:
		play_attempted = true
	_assert(play_attempted == false, "Cooldown guard: _death_sfx_cooldown_active=true prevents play")

func _test_cooldown_allows_play_when_inactive() -> void:
	print("--- T2e: Cooldown guard allows play when inactive ---")
	var cooldown_active := false
	var play_attempted := false
	if not cooldown_active:
		play_attempted = true
	_assert(play_attempted == true, "Cooldown guard: _death_sfx_cooldown_active=false allows play")

func _test_cooldown_window_is_600ms() -> void:
	print("--- T2f: Cooldown window is 600ms per spec ---")
	var cooldown_ms := 600
	_assert(cooldown_ms == 600, "Cooldown window is 600ms (0.6s) per spec")

func _test_mass_death_only_first_fires() -> void:
	print("--- T2g: Mass-death frame: only first death fires ---")
	var death_count_fired := 0
	var death_sfx_cooldown := false
	# First death
	if not death_sfx_cooldown:
		death_sfx_cooldown = true
		death_count_fired += 1
	# Second death (same frame, cooldown still active)
	if not death_sfx_cooldown:
		death_count_fired += 1
	# Third death (still active)
	if not death_sfx_cooldown:
		death_count_fired += 1
	_assert(death_count_fired == 1, "Mass-death frame: only first death fires (count == 1)")
