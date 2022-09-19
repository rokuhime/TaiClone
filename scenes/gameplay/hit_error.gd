extends Control

## Comment
signal indicator_changed(timing)

onready var root_viewport := $"/root" as Root
onready var miss := $Miss as ColorRect
onready var inaccurate := $Miss/Inaccurate as ColorRect
onready var accurate := $Miss/Inaccurate/Accurate as ColorRect
onready var hit_points := $HitPoints as Control
onready var avg_hit := $AverageHit as Control


func _ready() -> void:
	GlobalTools.send_signal(self, "hit_error_changed", root_viewport, "visibility_toggled")
	visibility_toggled()
	miss.modulate = Color("c8c8c8")

	## Comment
	var anchor := HitMarker.ACC_TIMING / HitMarker.INACC_TIMING / 2

	accurate.anchor_left = 0.5 - anchor
	accurate.anchor_right = 0.5 + anchor


## Applies the [member root_viewport]'s [SkinManager] to this [Node]. This method is seen in all [Node]s in the "Skinnables" group.
func apply_skin() -> void:
	miss.color = root_viewport.skin.miss_color
	inaccurate.color = root_viewport.skin.inaccurate_color
	accurate.color = root_viewport.skin.accurate_color


## Comment
func new_marker(type: int, timing: float, indicate: bool) -> void:
	## Comment
	var marker_obj := root_viewport.hit_marker.instance() as HitMarker

	hit_points.add_child(marker_obj)
	marker_obj.change_marker_properties(timing, type)

	## Comment
	var avg := 0.0

	## Comment
	var children := hit_points.get_child_count() - 1

	for i in range(hit_points.get_child_count() - 1):
		marker_obj = hit_points.get_child(i) as HitMarker
		if i < 25:
			marker_obj.modulate = Color(1, 1, 1, 1 - i / 25.0)

		else:
			marker_obj.queue_free()

		if marker_obj.type == int(HitObject.Score.MISS):
			children -= 1

		else:
			avg += marker_obj.anchor_left

	## Comment
	var anchor = avg / children if children else 0.5

	avg_hit.anchor_left = anchor
	avg_hit.anchor_right = anchor
	if indicate and type == int(HitObject.Score.INACCURATE):
		emit_signal("indicator_changed", timing)


## Comment
func visibility_toggled() -> void:
	visible = root_viewport.hit_error
