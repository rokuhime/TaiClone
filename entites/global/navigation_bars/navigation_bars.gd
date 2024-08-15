class_name NavigationBars
extends Control
var navigation_bar_tweens := []
var navigation_bars_enabled := false
@onready var navigation_bar_buttons := [
	$Bottom/Buttons/Button1, $Bottom/Buttons/Button2, $Bottom/Buttons/Button3
]
@onready var navigation_bar_labels := [
	$Top/HBoxContainer/LeftInfo/TopLabel, $Top/HBoxContainer/LeftInfo/BottomLabel,
	$Top/HBoxContainer/RightInfo/TopLabel, $Top/HBoxContainer/RightInfo/BottomLabel
]
@onready var back_button: Button = $Bottom/Buttons/BackButton

func toggle_navigation_bars(enabled: bool, smooth_transition := true) -> void:
	Global.change_focus()
	navigation_bars_enabled = enabled
	
	# end any ongoing navbar tweens
	if not navigation_bar_tweens.is_empty():
		for tween in navigation_bar_tweens:
			tween.kill()
	
	var top_bar := $Top as ColorRect
	var bottom_bar := $Bottom as ColorRect
	var screen_size = size.y
	
	if enabled:
		var top_tween := Global.create_smooth_tween()
		var bottom_tween := Global.create_smooth_tween()
		# slide into view
		top_tween.tween_property(top_bar, "position:y", 0, 0.5 if smooth_transition else 0)
		bottom_tween.tween_property(bottom_bar, "position:y", screen_size - bottom_bar.size.y, 0.5 if smooth_transition else 0)
		
		navigation_bar_tweens = [top_tween, bottom_tween]
		back_button.visible = true
		return
	
	var top_tween := Global.create_smooth_tween()
	var bottom_tween := Global.create_smooth_tween()
	# slide out of view
	top_tween.tween_property(top_bar, "position:y", -top_bar.size.y, 0.5 if smooth_transition else 0)
	bottom_tween.tween_property(bottom_bar, "position:y", screen_size, 0.5 if smooth_transition else 0)
	
	# set vars to allow killing them early if needed
	navigation_bar_tweens = [top_tween, bottom_tween]
	set_navbar_buttons([]) # disable nav buttons
	back_button.visible = false

# sets navbar button text
func set_navbar_buttons(button_info: Array) -> void:
	var idx := 0
	for button in navigation_bar_buttons:
		# if the idx exists...
		if button_info.size() - 1 >= idx:
			# if theres valid info...
			if button_info[idx] != null:
				button.visible = true
				button.focus_mode = Control.FOCUS_ALL
				button.text = button_info[idx]
				idx += 1
				continue
		# no info given, make invisible
		button.visible = false
		button.focus_mode = Control.FOCUS_NONE
		idx += 1

# sets test part of navbar
# 0, 1 = left, 2, 3 = right
func set_navbar_text(text_info: Array) -> void:
	var idx := 0
	for label in navigation_bar_labels:
		# if the idx exists...
		if text_info.size() - 1 >= idx:
			# if theres valid info...
			if text_info[idx] != null:
				label.visible = true
				label.text = text_info[idx]
				idx += 1
				continue
		# no info given, make invisible
		label.visible = false
		idx += 1

# wipes previous connections, and returns the pressed signals from navbar buttons
func get_navigation_bar_signals() -> Array:
	var button_signals := []
	for button in navigation_bar_buttons:
		# add connect callable to array
		button_signals.append(button.pressed)
	return button_signals
