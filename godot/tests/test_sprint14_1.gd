## Sprint 14.1 tests \u2014 bronze moment (league_unlocked signal + ceremony flag)
## and concede pill (loss path reuse). Slice A only.
## Usage: godot --headless --script tests/test_sprint14_1.gd
extends SceneTree

var pass_count := 0
var fail_count := 0
var test_count := 0

var _signal_emit_count: int = 0
var _last_league: String = ""

func _initialize() -> void:
	print("=== Sprint 14.1 Tests (bronze moment + concede) ===\n")
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

func assert_eq(a: Variant, b: Variant, msg: String) -> void:
	test_count += 1
	if a == b:
		pass_count += 1
	else:
		fail_count += 1
		print("  FAIL: %s (got %s, expected %s)" % [msg, str(a), str(b)])

func _on_league_unlocked(league_id: String) -> void:
	_signal_emit_count += 1
	_last_league = league_id

func _fresh_state() -> GameState:
	_signal_emit_count = 0
	_last_league = ""
	var gs := GameState.new()
	gs.league_unlocked.connect(_on_league_unlocked)
	return gs

func _run_all() -> void:
	_test_league_unlocked_signal_emits_on_third_scrapyard_win()
	_test_league_unlocked_signal_does_not_re_emit()
	_test_advance_league_transitions_scrapyard_to_bronze()
	_test_bronze_unlocked_flag_still_set()
	_test_concede_triggers_loss_outcome()
	_test_concede_applies_loss_bolts_cost()
	_test_concede_marks_opponent_as_faced()
	_test_pending_ceremony_flag_cleared_on_advance()

## T1 \u2014 signal fires exactly once when the 3rd scrapyard win closes the league.
func _test_league_unlocked_signal_emits_on_third_scrapyard_win() -> void:
	var gs := _fresh_state()
	gs.apply_match_result(true, "scrapyard_0")
	assert_eq(_signal_emit_count, 0, "T1 no signal after 1st win")
	gs.apply_match_result(true, "scrapyard_1")
	assert_eq(_signal_emit_count, 0, "T1 no signal after 2nd win")
	gs.apply_match_result(true, "scrapyard_2")
	assert_eq(_signal_emit_count, 1, "T1 signal emitted after 3rd win")
	assert_eq(_last_league, "bronze", "T1 league_id payload == 'bronze'")

## T2 \u2014 edge-detect: even if _check_progression re-runs (further wins /
## rematches / idempotent apply calls), signal must NOT re-emit.
func _test_league_unlocked_signal_does_not_re_emit() -> void:
	var gs := _fresh_state()
	gs.apply_match_result(true, "scrapyard_0")
	gs.apply_match_result(true, "scrapyard_1")
	gs.apply_match_result(true, "scrapyard_2")
	assert_eq(_signal_emit_count, 1, "T2 initial emit")
	# Re-win scrapyard_2 (rematch) \u2014 should not re-emit.
	gs.apply_match_result(true, "scrapyard_2")
	# Directly poke progression check again.
	gs._check_progression()
	gs._check_progression()
	gs._check_progression()
	assert_eq(_signal_emit_count, 1, "T2 no re-emit after repeated progression checks")

## T3 \u2014 advance_league() flips current_league scrapyard \u2192 bronze.
func _test_advance_league_transitions_scrapyard_to_bronze() -> void:
	var gs := _fresh_state()
	gs.apply_match_result(true, "scrapyard_0")
	gs.apply_match_result(true, "scrapyard_1")
	gs.apply_match_result(true, "scrapyard_2")
	assert_eq(gs.current_league, "scrapyard", "T3 pre: still scrapyard")
	gs.advance_league()
	assert_eq(gs.current_league, "bronze", "T3 post: bronze")

## T4 \u2014 regression: bronze_unlocked still flips true on 3rd win (spec \u00a71).
func _test_bronze_unlocked_flag_still_set() -> void:
	var gs := _fresh_state()
	assert_true(not gs.bronze_unlocked, "T4 pre: bronze_unlocked false")
	gs.apply_match_result(true, "scrapyard_0")
	gs.apply_match_result(true, "scrapyard_1")
	gs.apply_match_result(true, "scrapyard_2")
	assert_true(gs.bronze_unlocked, "T4 post: bronze_unlocked true")
	assert_true(gs.brottbrain_unlocked, "T4 post: brottbrain_unlocked true")

## T5 \u2014 concede produces loss outcome: apply_match_result(false, opp) bookkeeping
## matches what _on_match_end would do for an HP-zero loss. We simulate the path
## that _concede_fight takes: game_flow.finish_match(false).
func _test_concede_triggers_loss_outcome() -> void:
	var gf := GameFlow.new()
	gf.selected_opponent_index = 0
	var bolts_before := gf.game_state.bolts
	gf.finish_match(false)
	assert_true(not gf.last_match_won, "T5 last_match_won false")
	# Loss earnings: 40 - 50 = -10 \u2192 bolts goes down by 10.
	assert_eq(gf.game_state.bolts, bolts_before - 10, "T5 bolts net -10 on loss")

## T6 \u2014 concede applies the same bolts cost as any other loss (regression).
func _test_concede_applies_loss_bolts_cost() -> void:
	var gs := GameState.new()
	gs.bolts = 500
	# Loss: earn 40, repair 50, net -10.
	gs.apply_match_result(false, "scrapyard_0")
	assert_eq(gs.bolts, 490, "T6 bolts 500 \u2192 490 on loss")

## T7 \u2014 concede (loss) does NOT mark opponent as beaten (loss path spec).
func _test_concede_marks_opponent_as_faced() -> void:
	var gs := GameState.new()
	gs.apply_match_result(false, "scrapyard_0")
	assert_true("scrapyard_0" not in gs.opponents_beaten, "T7 loss does not add to opponents_beaten")
	# Regression: a subsequent win then correctly adds it.
	gs.apply_match_result(true, "scrapyard_0")
	assert_true("scrapyard_0" in gs.opponents_beaten, "T7 win adds to opponents_beaten")

## T8 \u2014 advance_league clears any in-flight pending-ceremony assumption.
## (We test the GameState side: advance is idempotent, no re-emit, current_league
##  is bronze, and subsequent progression checks don't spuriously re-emit.)
func _test_pending_ceremony_flag_cleared_on_advance() -> void:
	var gs := _fresh_state()
	gs.apply_match_result(true, "scrapyard_0")
	gs.apply_match_result(true, "scrapyard_1")
	gs.apply_match_result(true, "scrapyard_2")
	gs.advance_league()
	assert_eq(gs.current_league, "bronze", "T8 advanced to bronze")
	# Advance again: no-op, no re-emit.
	gs.advance_league()
	assert_eq(gs.current_league, "bronze", "T8 advance idempotent")
	assert_eq(_signal_emit_count, 1, "T8 no spurious re-emit post-advance")
