## test_s24_4_003_sfx_assets.gd
## [S24.4] Verify SFX asset files exist: new critical_hit.ogg + death.ogg; S24.3 preserved.
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
	print("\n=== test_s24_4_003_sfx_assets ===")

	# T3a: critical_hit.ogg exists (S24.4 new asset)
	_run_test("critical_hit.ogg exists at res://assets/audio/sfx/",
		FileAccess.file_exists("res://assets/audio/sfx/critical_hit.ogg"))

	# T3b: death.ogg exists (S24.4 new asset)
	_run_test("death.ogg exists at res://assets/audio/sfx/",
		FileAccess.file_exists("res://assets/audio/sfx/death.ogg"))

	# T3c: ATTRIBUTION.md exists and is non-empty
	var attr_exists := FileAccess.file_exists("res://assets/audio/sfx/ATTRIBUTION.md")
	_run_test("ATTRIBUTION.md exists at res://assets/audio/sfx/", attr_exists)
	if attr_exists:
		var f := FileAccess.open("res://assets/audio/sfx/ATTRIBUTION.md", FileAccess.READ)
		var content := f.get_as_text()
		f.close()
		_run_test("ATTRIBUTION.md contains critical_hit.ogg entry",
			"critical_hit.ogg" in content)
		_run_test("ATTRIBUTION.md contains death.ogg entry",
			"death.ogg" in content)
	else:
		# Skip sub-tests if file missing but count them as failures
		fail_count += 2
		print("  FAIL: ATTRIBUTION.md critical_hit.ogg entry (file missing)")
		print("  FAIL: ATTRIBUTION.md death.ogg entry (file missing)")

	# T3d: S24.3 asset hit.ogg preserved (scope fence)
	_run_test("hit.ogg preserved (S24.3 asset not overwritten)",
		FileAccess.file_exists("res://assets/audio/sfx/hit.ogg"))

	# T3e: S24.3 asset projectile_launch.ogg preserved (scope fence)
	_run_test("projectile_launch.ogg preserved (S24.3 asset not overwritten)",
		FileAccess.file_exists("res://assets/audio/sfx/projectile_launch.ogg"))

	# T3f: S21.5 asset win_chime.ogg preserved
	_run_test("win_chime.ogg preserved (S21.5 asset not overwritten)",
		FileAccess.file_exists("res://assets/audio/sfx/win_chime.ogg"))

	# T3g: S21.5 asset popup_whoosh.ogg preserved
	_run_test("popup_whoosh.ogg preserved (S21.5 asset not overwritten)",
		FileAccess.file_exists("res://assets/audio/sfx/popup_whoosh.ogg"))

	print("--- %d passed, %d failed ---" % [pass_count, fail_count])
	return fail_count

func _ready() -> void:
	var failures := run()
	quit(1 if failures > 0 else 0)
