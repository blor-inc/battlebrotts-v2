## test_s24_4_003_sfx_assets.gd
## [S24.4] Verify SFX asset files exist: new critical_hit.ogg + death.ogg; S24.3/S21.5 preserved.
## Usage: godot --headless --path godot/ --script res://tests/test_s24_4_003_sfx_assets.gd

extends SceneTree

var pass_count := 0
var fail_count := 0
var test_count := 0

func _initialize() -> void:
	print("=== test_s24_4_003_sfx_assets ===\n")
	_test_critical_hit_ogg_exists()
	_test_death_ogg_exists()
	_test_attribution_md_exists()
	_test_attribution_md_has_critical_hit_entry()
	_test_attribution_md_has_death_entry()
	_test_hit_ogg_preserved()
	_test_projectile_launch_ogg_preserved()
	_test_win_chime_ogg_preserved()
	_test_popup_whoosh_ogg_preserved()
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

func _test_critical_hit_ogg_exists() -> void:
	print("--- T3a: critical_hit.ogg exists (S24.4 new asset) ---")
	_assert(FileAccess.file_exists("res://assets/audio/sfx/critical_hit.ogg"),
		"critical_hit.ogg exists at res://assets/audio/sfx/")

func _test_death_ogg_exists() -> void:
	print("--- T3b: death.ogg exists (S24.4 new asset) ---")
	_assert(FileAccess.file_exists("res://assets/audio/sfx/death.ogg"),
		"death.ogg exists at res://assets/audio/sfx/")

func _test_attribution_md_exists() -> void:
	print("--- T3c: ATTRIBUTION.md exists ---")
	_assert(FileAccess.file_exists("res://assets/audio/sfx/ATTRIBUTION.md"),
		"ATTRIBUTION.md exists at res://assets/audio/sfx/")

func _test_attribution_md_has_critical_hit_entry() -> void:
	print("--- T3d: ATTRIBUTION.md contains critical_hit.ogg entry ---")
	if FileAccess.file_exists("res://assets/audio/sfx/ATTRIBUTION.md"):
		var f := FileAccess.open("res://assets/audio/sfx/ATTRIBUTION.md", FileAccess.READ)
		var content := f.get_as_text()
		f.close()
		_assert("critical_hit.ogg" in content,
			"ATTRIBUTION.md contains critical_hit.ogg entry (S24.4)")
	else:
		_assert(false, "ATTRIBUTION.md exists (required for critical_hit.ogg entry check)")

func _test_attribution_md_has_death_entry() -> void:
	print("--- T3e: ATTRIBUTION.md contains death.ogg entry ---")
	if FileAccess.file_exists("res://assets/audio/sfx/ATTRIBUTION.md"):
		var f := FileAccess.open("res://assets/audio/sfx/ATTRIBUTION.md", FileAccess.READ)
		var content := f.get_as_text()
		f.close()
		_assert("death.ogg" in content,
			"ATTRIBUTION.md contains death.ogg entry (S24.4)")
	else:
		_assert(false, "ATTRIBUTION.md exists (required for death.ogg entry check)")

func _test_hit_ogg_preserved() -> void:
	print("--- T3f: hit.ogg preserved (S24.3 scope fence) ---")
	_assert(FileAccess.file_exists("res://assets/audio/sfx/hit.ogg"),
		"hit.ogg preserved (S24.3 asset not overwritten)")

func _test_projectile_launch_ogg_preserved() -> void:
	print("--- T3g: projectile_launch.ogg preserved (S24.3 scope fence) ---")
	_assert(FileAccess.file_exists("res://assets/audio/sfx/projectile_launch.ogg"),
		"projectile_launch.ogg preserved (S24.3 asset not overwritten)")

func _test_win_chime_ogg_preserved() -> void:
	print("--- T3h: win_chime.ogg preserved (S21.5 scope fence) ---")
	_assert(FileAccess.file_exists("res://assets/audio/sfx/win_chime.ogg"),
		"win_chime.ogg preserved (S21.5 asset not overwritten)")

func _test_popup_whoosh_ogg_preserved() -> void:
	print("--- T3i: popup_whoosh.ogg preserved (S21.5 scope fence) ---")
	_assert(FileAccess.file_exists("res://assets/audio/sfx/popup_whoosh.ogg"),
		"popup_whoosh.ogg preserved (S21.5 asset not overwritten)")
