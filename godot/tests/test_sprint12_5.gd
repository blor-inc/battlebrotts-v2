## Sprint 12.5 test suite — JSON Match Logging
extends SceneTree

var pass_count := 0
var fail_count := 0
var test_count := 0

func _init() -> void:
	print("=== BattleBrotts Sprint 12.5 Test Suite ===")
	print("=== JSON Match Logging ===\n")

	test_json_log_disabled()
	test_json_log_enabled_captures_ticks()
	test_log_bot_state_fields()
	test_events_weapon_fired_and_damage()
	test_log_file_write()

	print("\n--- Results ---")
	print("%d passed, %d failed out of %d" % [pass_count, fail_count, test_count])
	quit(1 if fail_count > 0 else 0)

func _assert(cond: bool, msg: String) -> void:
	test_count += 1
	if cond:
		pass_count += 1
		print("  PASS: %s" % msg)
	else:
		fail_count += 1
		print("  FAIL: %s" % msg)

func _make_sim(enable_log: bool) -> CombatSim:
	var sim := CombatSim.new(42)
	sim.json_log_enabled = enable_log

	var b1 := BrottState.new()
	b1.team = 0
	b1.bot_name = "Alpha"
	b1.chassis_type = ChassisData.ChassisType.BRAWLER
	b1.weapon_types = [WeaponData.WeaponType.SHOTGUN]
	b1.armor_type = ArmorData.ArmorType.PLATING
	b1.module_types = [ModuleData.ModuleType.OVERCLOCK]
	b1.stance = 0
	b1.position = Vector2(4 * 32.0, 8 * 32.0)
	b1.setup()

	var b2 := BrottState.new()
	b2.team = 1
	b2.bot_name = "Bravo"
	b2.chassis_type = ChassisData.ChassisType.SCOUT
	b2.weapon_types = [WeaponData.WeaponType.MINIGUN]
	b2.armor_type = ArmorData.ArmorType.REACTIVE_MESH
	b2.module_types = [ModuleData.ModuleType.SHIELD_PROJECTOR]
	b2.stance = 2
	b2.position = Vector2(12 * 32.0, 8 * 32.0)
	b2.setup()

	sim.add_brott(b1)
	sim.add_brott(b2)
	return sim

func test_json_log_disabled() -> void:
	print("\n[Test] json_log_enabled=false produces no log")
	var sim := _make_sim(false)
	for _i in range(50):
		sim.simulate_tick()
	_assert(sim.get_json_log().size() == 0, "Log is empty when disabled")

func test_json_log_enabled_captures_ticks() -> void:
	print("\n[Test] json_log_enabled=true captures ticks")
	var sim := _make_sim(true)
	for _i in range(50):
		sim.simulate_tick()
	var log := sim.get_json_log()
	_assert(log.size() == 50, "Log has 50 entries for 50 ticks (got %d)" % log.size())
	_assert(log[0]["tick"] == 1, "First entry tick == 1")
	_assert(log[49]["tick"] == 50, "Last entry tick == 50")

func test_log_bot_state_fields() -> void:
	print("\n[Test] Log contains correct bot state fields")
	var sim := _make_sim(true)
	sim.simulate_tick()
	var log := sim.get_json_log()
	var entry: Dictionary = log[0]
	_assert(entry.has("tick"), "Entry has 'tick'")
	_assert(entry.has("bots"), "Entry has 'bots'")
	_assert(entry.has("events"), "Entry has 'events'")
	_assert(entry.has("match_state"), "Entry has 'match_state'")
	_assert(entry["match_state"] == "in_progress", "match_state is 'in_progress'")

	var bots: Array = entry["bots"]
	_assert(bots.size() == 2, "2 bots in entry")
	var bot: Dictionary = bots[0]
	var required_fields := ["id", "position_x", "position_y", "hp", "max_hp", "energy", "current_speed", "stance", "target_id", "facing_angle"]
	for field in required_fields:
		_assert(bot.has(field), "Bot state has '%s'" % field)

func test_events_weapon_fired_and_damage() -> void:
	print("\n[Test] Events capture weapon_fired and damage_dealt")
	var sim := _make_sim(true)
	# Run enough ticks for combat to happen
	for _i in range(200):
		sim.simulate_tick()
		if sim.match_over:
			break
	var log := sim.get_json_log()
	var found_weapon_fired := false
	var found_damage_dealt := false
	for entry in log:
		for evt in entry["events"]:
			if evt["type"] == "weapon_fired":
				found_weapon_fired = true
			if evt["type"] == "damage_dealt":
				found_damage_dealt = true
	_assert(found_weapon_fired, "Found weapon_fired event in log")
	_assert(found_damage_dealt, "Found damage_dealt event in log")

func test_log_file_write() -> void:
	print("\n[Test] Log file write works")
	var sim := _make_sim(true)
	for _i in range(10):
		sim.simulate_tick()
	var log := sim.get_json_log()
	var path := "res://tests/test_json_log_output.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	_assert(file != null, "Can open file for writing")
	if file:
		file.store_string(JSON.stringify(log, "  "))
		file.close()
		# Read back and verify
		var read_file := FileAccess.open(path, FileAccess.READ)
		_assert(read_file != null, "Can read file back")
		if read_file:
			var json := JSON.new()
			var err := json.parse(read_file.get_as_text())
			read_file.close()
			_assert(err == OK, "Written JSON is valid")
			_assert(json.data is Array, "Parsed data is Array")
			_assert(json.data.size() == 10, "Written log has 10 entries (got %d)" % json.data.size())
		# Cleanup
		DirAccess.remove_absolute(path)
