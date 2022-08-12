class_name HitError
extends Control

signal change_indicator(timing)

var acc_timing := 0.06
var inacc_timing := 0.145

onready var _accurate := $"HitPoints/Inaccurate/Accurate" as Control
onready var _avg_hit := $"AverageHit" as Control
onready var _hit_points := $"HitPoints" as Control
onready var _middle_marker := $"MiddleMarker"


func _ready() -> void:
	var anchor := acc_timing / inacc_timing / 2
	_accurate.anchor_left = 0.5 - anchor
	_accurate.anchor_right = 0.5 + anchor


func hit_error_toggled(new_visible: bool) -> void:
	visible = new_visible


func new_marker(type: String, timing: float, skin: SkinManager) -> void:
	var marker := _middle_marker.duplicate() as ColorRect
	_hit_points.add_child(marker)
	_hit_points.move_child(marker, 1)

	match type:
		"accurate":
			marker.modulate = skin.ACCURATE_COLOUR
		"inaccurate":
			marker.modulate = skin.INACCURATE_COLOUR
		"miss":
			marker.modulate = skin.MISS_COLOUR
		_:
			push_warning("Unknown marker type.")
			return

	var anchor := 0.5 + clamp(timing / inacc_timing, -1, 1) * rect_size.x / _hit_points.rect_size.x / 2
	marker.anchor_left = anchor
	marker.anchor_right = anchor

	# fade_out_markers and change_avg_hit_pos functions
	var avg := 0.0
	var misses := 0
	for i in range(_hit_points.get_child_count() - 1):
		marker = _hit_points.get_child(i + 1) as ColorRect
		if i < 25:
			marker.self_modulate = Color(1, 1, 1, 1 - i / 25.0)
		else:
			marker.queue_free()
		if marker.modulate == skin.MISS_COLOUR:
			misses += 1
		else:
			avg += marker.anchor_left

	var children := _hit_points.get_child_count() - misses - 1
	anchor = 0.5 if children == 0 else avg / children
	_avg_hit.anchor_left = anchor
	_avg_hit.anchor_right = anchor


	if type == "inaccurate":
		emit_signal("change_indicator", timing)
