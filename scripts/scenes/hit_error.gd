class_name HitError
extends Control

signal change_indicator(timing)

var acc_timing := 0.06
var inacc_timing := 0.145


func _ready() -> void:
	var accurate := $HitPoints/Inaccurate/Accurate as Control
	var anchor := acc_timing / inacc_timing / 2
	accurate.anchor_left = 0.5 - anchor
	accurate.anchor_right = 0.5 + anchor


func hit_error_toggled(new_visible: bool) -> void:
	visible = new_visible


func new_marker(type: int, timing: float, skin: SkinManager) -> void:
	var hit_points := $HitPoints as Control
	var marker := $MiddleMarker.duplicate() as ColorRect
	hit_points.add_child(marker)
	hit_points.move_child(marker, 1)

	match type:
		HitObject.Score.ACCURATE:
			marker.modulate = skin.accurate_color
		HitObject.Score.INACCURATE:
			marker.modulate = skin.inaccurate_color
		HitObject.Score.MISS:
			marker.modulate = skin.miss_color
		_:
			push_warning("Unknown marker type.")
			return

	var anchor := 0.5 + clamp(timing / inacc_timing, -1, 1) * rect_size.x / hit_points.rect_size.x / 2
	marker.anchor_left = anchor
	marker.anchor_right = anchor

	# fade_out_markers and change_avg_hit_pos functions
	var avg := 0.0
	var misses := 0
	for i in range(hit_points.get_child_count() - 1):
		marker = hit_points.get_child(i + 1) as ColorRect
		if i < 25:
			marker.self_modulate = Color(1, 1, 1, 1 - i / 25.0)
		else:
			marker.queue_free()
		if marker.modulate == skin.miss_color:
			misses += 1
		else:
			avg += marker.anchor_left

	var children := hit_points.get_child_count() - misses - 1
	anchor = avg / children if children else 0.5
	var avg_hit := $AverageHit as Control
	avg_hit.anchor_left = anchor
	avg_hit.anchor_right = anchor


	if type == HitObject.Score.INACCURATE:
		emit_signal("change_indicator", timing)
