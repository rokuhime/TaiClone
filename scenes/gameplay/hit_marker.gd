class_name HitMarker
extends ColorRect

## Comment
const ACC_TIMING := 0.03

## Comment
const INACC_TIMING := 0.07

## Comment
var type := -1

onready var root_viewport := $"/root" as Root


## Applies the [member root_viewport]'s [SkinManager] to this [Node]. This method is seen in all [Node]s in the "Skinnables" group.
func apply_skin() -> void:
	match type:
		HitObject.Score.ACCURATE:
			color = root_viewport.skin.accurate_color

		HitObject.Score.INACCURATE:
			color = root_viewport.skin.inaccurate_color

		HitObject.Score.MISS:
			color = root_viewport.skin.miss_color


## Comment
func change_marker_properties(timing: float, new_type: int) -> void:
	type = new_type
	apply_skin()

	## Comment
	var anchor := 0.5 + clamp(timing / INACC_TIMING, -1, 1) / 2

	anchor_left = anchor
	anchor_right = anchor
