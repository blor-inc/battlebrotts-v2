## S24.1-001 ShopScreen SFX bus routing — invariant: _shop_audio.bus == "SFX" after _ready().
## Usage: godot --headless --path godot/ --script res://tests/test_sprint24_1_001_shop_screen_sfx_bus.gd
extends SceneTree
var pass_count := 0
var fail_count := 0
var test_count := 0
const ShopScreenScript := preload("res://ui/shop_screen.gd")

func _initialize() -> void:
	print("=== S24.1-001 ShopScreen SFX bus routing ===\n")
	_test_shop_audio_routes_to_sfx()
	print("\n=== Results: %d passed, %d failed, %d total ===" % [pass_count, fail_count, test_count])
	quit(1 if fail_count > 0 else 0)

func _assert_eq(a: Variant, b: Variant, msg: String) -> void:
	test_count += 1
	if a == b:
		pass_count += 1
	else:
		fail_count += 1
		print("  FAIL: %s (got %s, expected %s)" % [msg, str(a), str(b)])

func _test_shop_audio_routes_to_sfx() -> void:
	var shop: Control = ShopScreenScript.new()
	get_root().add_child(shop)
	_assert_eq(shop._shop_audio.bus, &"SFX", "I3c: _shop_audio.bus == SFX")
	shop.queue_free()
