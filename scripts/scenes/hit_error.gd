extends Control

var _late_early_simple_display := true

var _g: Gameplay
var _timing_indicator: Label
var _tween: Tween

onready var _accurate := $"HitPoints/Inaccurate/Accurate" as Control
onready var _avg_hit := $"AverageHit" as Control
onready var _hit_points := $"HitPoints" as Control
onready var _middle_marker := $"MiddleMarker"


func gameplay_ready() -> void:
	_g = $"/root/Gameplay" as Gameplay
	_timing_indicator = $"../../BarLeft/TimingIndicator" as Label
	_tween = $"../../BarLeft/TimingIndicator/Tween" as Tween

	var anchor := _g.acc_timing / _g.inacc_timing / 2
	_accurate.anchor_left = 0.5 - anchor
	_accurate.anchor_right = 0.5 + anchor


func hit_error_toggled(new_visible: bool) -> void:
	visible = new_visible


func late_early_changed(new_value: int) -> void:
	_late_early_simple_display = new_value < 2
	_timing_indicator.visible = new_value > 0


func new_marker(type: String, timing: float) -> void:
	var marker := _middle_marker.duplicate() as ColorRect
	_hit_points.add_child(marker)
	_hit_points.move_child(marker, 1)

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

	var anchor := 0.5 + clamp(timing / _g.inacc_timing, -1, 1) * rect_size.x / _hit_points.rect_size.x / 2
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
		if marker.modulate == skin.miss_colour:
			misses += 1
		else:
			avg += marker.anchor_left

	var children := _hit_points.get_child_count() - misses - 1
	anchor = 0.5 if children == 0 else avg / children
	_avg_hit.anchor_left = anchor
	_avg_hit.anchor_right = anchor


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
