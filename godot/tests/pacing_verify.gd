## Pacing verification: 600 matches, tracking duration + timeout
extends SceneTree

const MATCHES_PER_MATCHUP := 100
const CHASSIS_NAMES := ["Scout", "Brawler", "Fortress"]

var results := {}
var total_matches := 0
var total_ticks := 0
var timeout_count := 0
var match_durations := []  # seconds
var matchup_durations := {}  # key -> [durations]
var matchup_timeouts := {}

func _init() -> void:
	print("=== Pacing Re-Verification (2x HP) ===\n")
	
	var chassis_types := [
		ChassisData.ChassisType.SCOUT,
		ChassisData.ChassisType.BRAWLER,
		ChassisData.ChassisType.FORTRESS,
	]
	var weapon_types := [
		WeaponData.WeaponType.MINIGUN,
		WeaponData.WeaponType.RAILGUN,
		WeaponData.WeaponType.SHOTGUN,
		WeaponData.WeaponType.MISSILE_POD,
		WeaponData.WeaponType.PLASMA_CUTTER,
		WeaponData.WeaponType.ARC_EMITTER,
		WeaponData.WeaponType.FLAK_CANNON,
	]
	
	for i in range(chassis_types.size()):
		for j in range(i, chassis_types.size()):
			var ca: ChassisData.ChassisType = chassis_types[i]
			var cb: ChassisData.ChassisType = chassis_types[j]
			var key := "%s_vs_%s" % [CHASSIS_NAMES[i], CHASSIS_NAMES[j]]
			results[key] = {"wins_a": 0, "wins_b": 0, "draws": 0}
			matchup_durations[key] = []
			matchup_timeouts[key] = 0
			
			for m in MATCHES_PER_MATCHUP:
				var seed_val := i * 10000 + j * 1000 + m
				var rng := RandomNumberGenerator.new()
				rng.seed = seed_val
				
				var w1a: WeaponData.WeaponType = weapon_types[rng.randi() % weapon_types.size()]
				var w1b: WeaponData.WeaponType = weapon_types[rng.randi() % weapon_types.size()]
				var w2a: WeaponData.WeaponType = weapon_types[rng.randi() % weapon_types.size()]
				var w2b: WeaponData.WeaponType = weapon_types[rng.randi() % weapon_types.size()]
				
				var sim := CombatSim.new(seed_val)
				
				var b1 := BrottState.new()
				b1.team = 0
				b1.chassis_type = ca
				b1.weapon_types = [w1a, w1b] as Array[WeaponData.WeaponType]
				b1.armor_type = ArmorData.ArmorType.NONE
				b1.module_types = [] as Array[ModuleData.ModuleType]
				b1.position = Vector2(64, 256)
				b1.stance = rng.randi() % 3
				b1.setup()
				
				var b2 := BrottState.new()
				b2.team = 1
				b2.chassis_type = cb
				b2.weapon_types = [w2a, w2b] as Array[WeaponData.WeaponType]
				b2.armor_type = ArmorData.ArmorType.NONE
				b2.module_types = [] as Array[ModuleData.ModuleType]
				b2.position = Vector2(448, 256)
				b2.stance = rng.randi() % 3
				b2.setup()
				
				sim.add_brott(b1)
				sim.add_brott(b2)
				
				while not sim.match_over:
					sim.simulate_tick()
				
				var duration_sec: float = float(sim.tick_count) / float(CombatSim.TICKS_PER_SEC)
				match_durations.append(duration_sec)
				matchup_durations[key].append(duration_sec)
				total_ticks += sim.tick_count
				
				var timed_out: bool = sim.tick_count >= CombatSim.MATCH_TIMEOUT_TICKS
				if timed_out:
					timeout_count += 1
					matchup_timeouts[key] += 1
				
				if sim.winner_team == 0:
					results[key]["wins_a"] += 1
				elif sim.winner_team == 1:
					results[key]["wins_b"] += 1
				else:
					results[key]["draws"] += 1
				
				total_matches += 1
	
	# Sort durations for percentiles
	match_durations.sort()
	
	var avg_dur: float = 0.0
	for d in match_durations:
		avg_dur += d
	avg_dur /= match_durations.size()
	
	var median_dur: float = match_durations[match_durations.size() / 2]
	var p10: float = match_durations[int(match_durations.size() * 0.1)]
	var p90: float = match_durations[int(match_durations.size() * 0.9)]
	var min_dur: float = match_durations[0]
	var max_dur: float = match_durations[match_durations.size() - 1]
	
	print("Total matches: %d" % total_matches)
	print("\n--- PACING ---")
	print("Average match length: %.1f sec" % avg_dur)
	print("Median match length:  %.1f sec" % median_dur)
	print("P10 / P90:            %.1f / %.1f sec" % [p10, p90])
	print("Min / Max:            %.1f / %.1f sec" % [min_dur, max_dur])
	print("Timeout rate:         %d/%d (%.1f%%)" % [timeout_count, total_matches, 100.0 * timeout_count / total_matches])
	
	print("\n--- TTK BY MATCHUP ---")
	for key in matchup_durations:
		var durs: Array = matchup_durations[key]
		var avg: float = 0.0
		for d in durs:
			avg += d
		avg /= durs.size()
		durs.sort()
		var med: float = durs[durs.size() / 2]
		var to_rate: float = 100.0 * matchup_timeouts[key] / durs.size()
		print("%s: avg %.1fs, median %.1fs, timeout %.1f%%" % [key, avg, med, to_rate])
	
	print("\n--- MATCHUP WIN RATES ---")
	for key in results:
		var r = results[key]
		var parts: PackedStringArray = key.split("_vs_")
		var total: int = r["wins_a"] + r["wins_b"] + r["draws"]
		print("%s: %s %.0f%% / %s %.0f%% / draws %d" % [
			key, parts[0], 100.0 * r["wins_a"] / total, parts[1], 100.0 * r["wins_b"] / total, r["draws"]
		])
	
	print("\n=== Verification Complete ===")
	quit(0)
