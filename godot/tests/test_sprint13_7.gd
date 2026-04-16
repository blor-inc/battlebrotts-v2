## Sprint 13.7 — Item Token Router tests (Nutts-A)
## Usage: godot --headless --script tests/test_sprint13_7.gd
##
## Covers spec §5 Router tests 1-6 + empty-pool guard test 16.
## (GameState grant/lose + trick integration tests are Nutts-B's responsibility.)
extends SceneTree

var pass_count := 0
var fail_count := 0
var test_count := 0

func _initialize() -> void:
	print("=== Sprint 13.7 Item Token Router Tests (Nutts-A) ===\n")
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
	_test_1_resolve_direct_armor()
	_test_2_resolve_direct_weapon()
	_test_3_resolve_random_weak_pool()
	_test_4_resolve_random_module_pool()
	_test_5_resolve_bogus_returns_empty()
	_test_6_display_name_non_empty_for_pool_entries()
	_test_16_empty_pool_and_no_infinite_loop()

# --- Test 1: direct armor token ---
func _test_1_resolve_direct_armor() -> void:
	print("Test 1: resolve_token(\"plating\") → CAT_ARMOR + PLATING")
	var r: Dictionary = ItemTokens.resolve_token("plating")
	assert_eq(r.get("category", -1), ItemTokens.CAT_ARMOR, "category is CAT_ARMOR")
	assert_eq(r.get("type", -1), ArmorData.ArmorType.PLATING, "type is ArmorType.PLATING")
	assert_eq(r.get("token", ""), "plating", "token echoed back")

# --- Test 2: direct weapon token ---
func _test_2_resolve_direct_weapon() -> void:
	print("Test 2: resolve_token(\"minigun\") → CAT_WEAPON + MINIGUN")
	var r: Dictionary = ItemTokens.resolve_token("minigun")
	assert_eq(r.get("category", -1), ItemTokens.CAT_WEAPON, "category is CAT_WEAPON")
	assert_eq(r.get("type", -1), WeaponData.WeaponType.MINIGUN, "type is WeaponType.MINIGUN")

# --- Test 3: random_weak pool ---
func _test_3_resolve_random_weak_pool() -> void:
	print("Test 3: resolve_token(\"random_weak\") → category in {weapon, armor, module}")
	seed(12345)
	var r: Dictionary = ItemTokens.resolve_token("random_weak")
	assert_true(not r.is_empty(), "random_weak resolves to non-empty dict")
	var cat: int = int(r.get("category", -1))
	var valid := cat == ItemTokens.CAT_WEAPON or cat == ItemTokens.CAT_ARMOR or cat == ItemTokens.CAT_MODULE
	assert_true(valid, "category is weapon, armor, or module")
	assert_true(r.has("token"), "resolved dict has token field")

# --- Test 4: random_module pool ---
func _test_4_resolve_random_module_pool() -> void:
	print("Test 4: resolve_token(\"random_module\") → CAT_MODULE")
	seed(54321)
	for i in range(10):
		var r: Dictionary = ItemTokens.resolve_token("random_module")
		assert_eq(r.get("category", -1), ItemTokens.CAT_MODULE, "iter %d: category is CAT_MODULE" % i)

# --- Test 5: bogus token ---
func _test_5_resolve_bogus_returns_empty() -> void:
	print("Test 5: resolve_token(\"bogus_token\") → {}")
	var r: Dictionary = ItemTokens.resolve_token("bogus_token")
	assert_true(r.is_empty(), "bogus token returns empty dict")
	var r2: Dictionary = ItemTokens.resolve_token("")
	assert_true(r2.is_empty(), "empty-string token returns empty dict")

# --- Test 6: display_name non-empty for every random_weak pool entry ---
func _test_6_display_name_non_empty_for_pool_entries() -> void:
	print("Test 6: display_name returns non-empty for every random_weak pool entry")
	for token in ItemTokens.POOLS["random_weak"]:
		var r: Dictionary = ItemTokens.resolve_token(String(token))
		assert_true(not r.is_empty(), "token %s resolves" % [token])
		var name := ItemTokens.display_name(r)
		assert_true(name != "", "display_name non-empty for %s" % [token])
	# Also: display_name on {} → ""
	assert_eq(ItemTokens.display_name({}), "", "display_name({}) is \"\"")

# --- Test 16: empty-pool guard + no infinite loop ---
# POOLS is const — can't monkey-patch. We verify two guarantees instead:
#   (a) Every pool entry is itself a valid DIRECT token (so pools can't silently
#       degrade to unresolvable picks → no hidden recursion issue).
#   (b) resolve_token on an unknown random_* token returns {} without hanging.
#       (Running inside a finite loop with a hard iteration cap is our "finite time" proxy.)
func _test_16_empty_pool_and_no_infinite_loop() -> void:
	print("Test 16: empty-pool / unknown-token guard (no infinite loop, no retry)")
	# (a) Every POOLS entry maps to a DIRECT token.
	for pool_name in ItemTokens.POOLS:
		var entries: Array = ItemTokens.POOLS[pool_name]
		for entry in entries:
			assert_true(
				ItemTokens.DIRECT.has(String(entry)),
				"pool %s entry %s is a valid DIRECT token" % [pool_name, entry]
			)
	# (b) Unknown random_* token resolves to {} immediately (no loop).
	var r: Dictionary = ItemTokens.resolve_token("random_does_not_exist")
	assert_true(r.is_empty(), "unknown random_* token returns {}")
	# (c) Hammer random_weak 500× — proves no retry loop explodes.
	seed(99)
	for i in range(500):
		var rr: Dictionary = ItemTokens.resolve_token("random_weak")
		if rr.is_empty():
			fail_count += 1
			test_count += 1
			print("  FAIL: random_weak returned {} on iter %d" % i)
			return
	test_count += 1
	pass_count += 1
	print("  PASS: 500 random_weak resolutions all non-empty")
