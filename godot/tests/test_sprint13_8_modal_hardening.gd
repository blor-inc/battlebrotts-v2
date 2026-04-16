## Sprint 13.8 — Modal hardening tests (Nutts-A)
## Usage: godot --headless --script tests/test_sprint13_8_modal_hardening.gd
##
## Covers:
##   - _trick_shown guard: second call to show_trick() is a no-op
##     (verified by a controlled crash pattern: first call fails on @onready
##      node access without a scene, but sets the flag FIRST because it's
##      assigned before any node touch. Second call returns early and is silent.)
##   - Modal source declares the guard and resets semantics are one-shot.
##   - Shop resolve loop orders queue_free() BEFORE apply_trick_choice()
##     (regression guard via source grep).
extends SceneTree

var pass_count := 0
var fail_count := 0
var test_count := 0

func _initialize() -> void:
	print("=== Sprint 13.8 Modal Hardening Tests (Nutts-A) ===\n")
	_run_all()
	print("\n=== Results: %d passed, %d failed, %d total ===" % [pass_count, fail_count, test_count])
	if fail_count > 0:
		quit(1)
	else:
		quit(0)

func assert_eq(a, b, msg: String) -> void:
	test_count += 1
	if a == b:
		pass_count += 1
	else:
		fail_count += 1
		print("  FAIL: %s (got %s, expected %s)" % [msg, str(a), str(b)])

func assert_true(cond: bool, msg: String) -> void:
	test_count += 1
	if cond:
		pass_count += 1
	else:
		fail_count += 1
		print("  FAIL: %s" % msg)

func _run_all() -> void:
	_test_guard_field_declared()
	_test_guard_check_precedes_assignments()
	_test_guard_default_false()
	_test_guard_second_call_returns_early()
	_test_shop_swap_order_in_source()
	_test_shop_source_documents_swap()
	_test_apply_trick_good_choice_mutates_state()

func _read_source(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var txt: String = f.get_as_text()
	f.close()
	return txt

func _test_guard_field_declared() -> void:
	print("Source: modal declares _trick_shown guard field")
	var src: String = _read_source("res://ui/trick_choice_modal.gd")
	assert_true(src.find("var _trick_shown") != -1, "_trick_shown var present")
	assert_true(src.find("_trick_shown = true") != -1, "_trick_shown gets set true in show_trick")

func _test_guard_check_precedes_assignments() -> void:
	print("Source: guard check occurs before any @onready node access in show_trick")
	var src: String = _read_source("res://ui/trick_choice_modal.gd")
	var guard_return: int = src.find("if _trick_shown:")
	var first_dialogue: int = src.find("_dialogue.text")
	assert_true(guard_return != -1, "guard return present")
	assert_true(first_dialogue != -1, "dialogue assignment present")
	assert_true(guard_return < first_dialogue, "guard precedes @onready node writes")

func _test_guard_default_false() -> void:
	print("Behavior: bare-script modal has _trick_shown=false by default")
	# Build a bare instance (no scene, no @onready nodes) to read the default.
	var script := load("res://ui/trick_choice_modal.gd")
	var modal = script.new()
	assert_true(modal != null, "modal instantiates via script.new()")
	assert_eq(modal._trick_shown, false, "_trick_shown defaults to false")
	modal.free()

func _test_guard_second_call_returns_early() -> void:
	print("Behavior: with _trick_shown=true, show_trick() returns before touching nodes")
	var script := load("res://ui/trick_choice_modal.gd")
	var modal = script.new()
	# Pre-arm the guard. If show_trick honors it, the call touches nothing
	# and does not raise even though @onready vars are null.
	modal._trick_shown = true
	modal.show_trick({"id": "dummy"})
	assert_eq(modal._trick_shown, true, "_trick_shown remains true after re-entry")
	assert_true(modal._trick.is_empty(), "_trick not overwritten on re-entry (no-op)")
	modal.free()

func _test_shop_swap_order_in_source() -> void:
	print("Source: shop_screen.gd places queue_free() before apply_trick_choice()")
	var src: String = _read_source("res://ui/shop_screen.gd")
	var qf: int = src.find("modal.queue_free()")
	var ap: int = src.find("apply_trick_choice(trick, choice_key)")
	assert_true(qf != -1, "queue_free call present")
	assert_true(ap != -1, "apply_trick_choice call present")
	assert_true(qf != -1 and ap != -1 and qf < ap, "queue_free() precedes apply_trick_choice() (S13.8 swap)")

func _test_shop_source_documents_swap() -> void:
	print("Source: shop_screen.gd comments reference S13.8 swap rationale")
	var src: String = _read_source("res://ui/shop_screen.gd")
	assert_true(src.find("S13.8") != -1, "S13.8 comment marker present in shop_screen.gd")

func _test_apply_trick_good_choice_mutates_state() -> void:
	## Sanity: apply_trick_choice on a valid choice works; bad key would
	## crash production — the S13.8 swap ensures the modal is reclaimed first.
	print("Apply: good choice_key mutates _tricks_seen")
	var gs := GameState.new()
	var trick: Dictionary = {
		"id": "t_s13_8_probe",
		"brottbrain_text": "x", "prompt": "x",
		"choice_a": {"label": "A", "flavor_line": "a", "effect_type": 0, "effect_value": 1},
		"choice_b": {"label": "B", "flavor_line": "b", "effect_type": 0, "effect_value": -1},
	}
	var before: int = gs._tricks_seen.size()
	gs.apply_trick_choice(trick, "choice_a")
	assert_eq(gs._tricks_seen.size(), before + 1, "trick id recorded after valid apply")
	assert_true(gs._tricks_seen.has("t_s13_8_probe"), "correct id stored")
