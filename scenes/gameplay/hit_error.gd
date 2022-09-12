class_name HitError
extends Control

## Comment
signal indicator_changed(timing)

## Comment
const ACC_TIMING := 0.03

## Comment
const INACC_TIMING := 0.07

onready var root_viewport := $"/root" as Root
onready var miss := $Miss as ColorRect
onready var hit_points := $HitPoints as Control
onready var inaccurate := $HitPoints/Inaccurate as ColorRect
onready var accurate := $HitPoints/Inaccurate/Accurate as ColorRect
onready var middle_marker := $MiddleMarker
onready var avg_hit := $AverageHit as Control


func _ready() -> void:
	GlobalTools.send_signal(self, "hit_error_changed", root_viewport, "visibility_toggled")
	visibility_toggled()
	add_to_group("Skinnables")
	apply_skin()

	## Comment
	var self_modulate_color := Color("c8c8c8")

	miss.self_modulate = self_modulate_color
	inaccurate.self_modulate = self_modulate_color
	accurate.self_modulate = self_modulate_color

	## Comment
	var anchor := ACC_TIMING / INACC_TIMING / 2

	accurate.anchor_left = 0.5 - anchor
	accurate.anchor_right = 0.5 + anchor


## Comment
func apply_skin() -> void:
	miss.color = root_viewport.skin.miss_color
	inaccurate.color = root_viewport.skin.inaccurate_color
	accurate.color = root_viewport.skin.accurate_color


## Comment
func new_marker(type: int, timing: float, indicate: bool) -> void:
	## Comment
	var marker_obj := middle_marker.duplicate() as ColorRect

	hit_points.add_child(marker_obj)
	hit_points.move_child(marker_obj, 1)
	match type:
		HitObject.Score.ACCURATE:
			marker_obj.modulate = root_viewport.skin.accurate_color

		HitObject.Score.INACCURATE:
			marker_obj.modulate = root_viewport.skin.inaccurate_color

		HitObject.Score.MISS:
			marker_obj.modulate = root_viewport.skin.miss_color

		_:
			push_warning("Unknown marker type.")
			return

	## Comment
	var anchor := 0.5 + clamp(timing / INACC_TIMING, -1, 1) * rect_size.x / hit_points.rect_size.x / 2

	marker_obj.anchor_left = anchor
	marker_obj.anchor_right = anchor

	## Comment
	var avg := 0.0

	## Comment
	var misses := 0

	for i in range(hit_points.get_child_count() - 1):
		marker_obj = hit_points.get_child(i + 1) as ColorRect
		if i < 25:
			marker_obj.self_modulate = Color(1, 1, 1, 1 - i / 25.0)

		else:
			marker_obj.queue_free()

		if marker_obj.modulate == miss.color:
			misses += 1

		else:
			avg += marker_obj.anchor_left

	## Comment
	var children := hit_points.get_child_count() - misses - 1

	anchor = avg / children if children else 0.5
	avg_hit.anchor_left = anchor
	avg_hit.anchor_right = anchor
	if indicate and type == int(HitObject.Score.INACCURATE):
		emit_signal("indicator_changed", timing)


## Comment
func visibility_toggled() -> void:
	visible = root_viewport.hit_error
