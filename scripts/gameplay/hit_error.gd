extends Control

## Comment
signal change_indicator(timing)

onready var accurate := $HitPoints/Inaccurate/Accurate as ColorRect
onready var avg_hit := $AverageHit as Control
onready var hit_points := $HitPoints as Control
onready var inaccurate := $HitPoints/Inaccurate as ColorRect
onready var middle_marker := $MiddleMarker
onready var miss := $Miss as ColorRect
onready var taiclone := $"/root" as Root


func _ready() -> void:
	## Comment
	var self_modulate_color := Color("c8c8c8")

	miss.color = taiclone.skin.miss_color
	miss.self_modulate = self_modulate_color
	inaccurate.color = taiclone.skin.inaccurate_color
	inaccurate.self_modulate = self_modulate_color
	accurate.color = taiclone.skin.accurate_color
	accurate.self_modulate = self_modulate_color

	## Comment
	var anchor := taiclone.acc_timing / taiclone.inacc_timing / 2

	accurate.anchor_left = 0.5 - anchor
	accurate.anchor_right = 0.5 + anchor


## Comment
func hit_error_toggled(new_visible: bool) -> void:
	visible = new_visible


## Comment
func new_marker(type: int, timing: float, skin: SkinManager) -> void:
	## Comment
	var marker := middle_marker.duplicate() as ColorRect

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

	## Comment
	var anchor := 0.5 + clamp(timing / taiclone.inacc_timing, -1, 1) * rect_size.x / hit_points.rect_size.x / 2

	marker.anchor_left = anchor
	marker.anchor_right = anchor

	## Comment
	var avg := 0.0

	## Comment
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

	## Comment
	var children := hit_points.get_child_count() - misses - 1

	anchor = avg / children if children else 0.5
	avg_hit.anchor_left = anchor
	avg_hit.anchor_right = anchor
	if type == int(HitObject.Score.INACCURATE):
		emit_signal("change_indicator", timing)
