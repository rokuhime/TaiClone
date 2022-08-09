extends CanvasItem

const HIT_POSITIONS := []

var _late_early_simple_display := true

onready var _avg_hit := $"AverageHit" as Control
onready var _g := $"../.." as Gameplay
onready var _hit_points := $"HitPoints"
onready var _middle_marker := $"MiddleMarker"
onready var _timing_indicator := $"../../BarLeft/TimingIndicator" as Label
onready var _tween := $"../../BarLeft/TimingIndicator/Tween" as Tween


func hit_error_toggled(new_visible: bool) -> void:
	visible = new_visible


func late_early_changed(new_value: int) -> void:
	_late_early_simple_display = new_value < 2
	_timing_indicator.visible = new_value > 0


func new_marker(type: String, timing: float) -> void:
	var marker := _middle_marker.duplicate() as ColorRect
	_hit_points.add_child(marker)
	_hit_points.move_child(marker, 0)

	var skin := _g.skin
	match type:
		"accurate":
			marker.modulate = skin.accurate_colour
		"inaccurate":
			marker.modulate = skin.inaccurate_colour
		"miss":
			marker.modulate = skin.miss_colour
		_:
			push_warning("Unknown marker type.")
			return

	marker.rect_position = Vector2(timing * 1325 + 212, 0)

	HIT_POSITIONS.append(timing)

	# fade_out_markers function
	for i in range(_hit_points.get_child_count()):
		marker = _hit_points.get_child(i) as ColorRect
		if i < 25:
			marker.self_modulate = Color(1, 1, 1, 1 - i / 25.0)
		else:
			marker.queue_free()
			HIT_POSITIONS.remove(0)

	# change_avg_hit_pos function
	var avg := 0.0
	for hp in HIT_POSITIONS:
		avg += float(hp)

	_avg_hit.rect_position = Vector2(avg * 1325 / HIT_POSITIONS.size() + 212, 18)


	if type != "inaccurate":
		return

	# change_indicator function
	var num := int(timing * 1000)
	if timing > 0:
		_timing_indicator.text = "LATE" if _late_early_simple_display else "+%s" % num
		_timing_indicator.modulate = Color("5a5aff")
	else:
		_timing_indicator.text = "EARLY" if _late_early_simple_display else str(num)
		_timing_indicator.modulate = Color("ff5a5a")

	if not _tween.remove(_timing_indicator, "self_modulate"):
		push_warning("Attempted to remove timing indicator tween.")
	if not _tween.interpolate_property(_timing_indicator, "self_modulate", Color.white, Color.transparent, 0.5, Tween.TRANS_QUART):
		push_warning("Attempted to tween timing indicator.")
	if not _tween.start():
		push_warning("Attempted to start timing indicator tween.")
