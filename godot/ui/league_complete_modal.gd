## S14.1 — League complete modal (bronze moment).
## Fires on the ResultScreen \u2192 Shop transition when the player has just
## cleared all three Scrapyard opponents. Fade-in, placeholder badge pulse,
## single "Continue" CTA. On Continue: tells GameState to advance league,
## emits modal_dismissed, frees self. No audio this sprint (S14.1 plan \u00a73).
class_name LeagueCompleteModal
extends CanvasLayer

signal modal_dismissed

const BRONZE := Color(0.804, 0.498, 0.196)  ## #CD7F32-ish, muted bronze
const FADE_MS := 400

var _state: GameState
var _overlay: ColorRect
var _badge: ColorRect

func setup(state: GameState) -> void:
	_state = state

func _ready() -> void:
	layer = 110  # above any other modals/screens

	_overlay = ColorRect.new()
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.color = Color(0, 0, 0, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	var vbox := VBoxContainer.new()
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -220.0
	vbox.offset_top = -180.0
	vbox.offset_right = 220.0
	vbox.offset_bottom = 180.0
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	_overlay.add_child(vbox)

	var header := Label.new()
	header.text = "SCRAPYARD CLEARED"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 28)
	vbox.add_child(header)

	# Placeholder bronze badge \u2014 a ColorRect we pulse with a tween.
	var badge_wrap := CenterContainer.new()
	vbox.add_child(badge_wrap)
	_badge = ColorRect.new()
	_badge.custom_minimum_size = Vector2(90, 90)
	_badge.color = BRONZE
	badge_wrap.add_child(_badge)

	var copy := Label.new()
	copy.text = "Your brott earned it. Welcome to Bronze."
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD
	copy.custom_minimum_size = Vector2(380, 0)
	vbox.add_child(copy)

	var btn := Button.new()
	btn.text = "Continue"
	btn.custom_minimum_size = Vector2(180, 40)
	btn.pressed.connect(_on_continue)
	var btn_row := CenterContainer.new()
	btn_row.add_child(btn)
	vbox.add_child(btn_row)

	_animate_in()

func _animate_in() -> void:
	# Fade overlay to dim; pulse the badge subtly.
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(_overlay, "color:a", 0.7, float(FADE_MS) / 1000.0)
	# Badge idle pulse: modulate brightness, loop.
	var pulse := create_tween()
	pulse.set_loops()
	pulse.tween_property(_badge, "modulate", Color(1.15, 1.15, 1.15), 0.8)
	pulse.tween_property(_badge, "modulate", Color(0.85, 0.85, 0.85), 0.8)

func _on_continue() -> void:
	if _state != null:
		_state.advance_league()
	modal_dismissed.emit()
	queue_free()
