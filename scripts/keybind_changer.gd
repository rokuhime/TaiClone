class_name KeybindChanger
extends Node

const KEYBINDS := {}

var _currently_changing := ""

onready var _left_don_butt := $"LeftDon/Button" as Button
onready var _left_kat_butt := $"LeftKat/Button" as Button
onready var _right_don_butt := $"RightDon/Button" as Button
onready var _right_kat_butt := $"RightKat/Button" as Button


func _ready() -> void:
	for button in ["LeftDon", "LeftKat", "RightDon", "RightKat"]:
		var action_list := InputMap.get_action_list(str(button))
		change_text(str(button), action_list[0])


func _input(event: InputEvent) -> void:
	if _currently_changing != "":
		if event is InputEventJoypadButton or event is InputEventKey:
			change_key(_currently_changing, event)
			button_pressed(_currently_changing)
		else:
			push_warning("Unsupported InputEvent type.")


func button_pressed(type: String) -> void:
	if _currently_changing == "":
		_currently_changing = type
		change_text(_currently_changing, InputEvent.new(), true)
	else:
		var action_list := InputMap.get_action_list(_currently_changing)
		change_text(_currently_changing, action_list[0])
		_currently_changing = ""


func change_key(button: String, event: InputEvent) -> void:
	# load_keybinds function
	InputMap.action_erase_events(str(button))
	InputMap.action_add_event(str(button), event)

	_currently_changing = ""
	KEYBINDS[button] = event
	change_text(button, event)


func change_text(button: String, event: InputEvent, pressed := false) -> void:
	var button_object: Button
	match button:
		"LeftDon":
			button_object = _left_don_butt
		"LeftKat":
			button_object = _left_kat_butt
		"RightDon":
			button_object = _right_don_butt
		"RightKat":
			button_object = _right_kat_butt
		_:
			push_warning("Unknown input.")
			return
	if event is InputEventJoypadButton:
		button_object.text = "Joystick Button %s" % (event as InputEventJoypadButton).button_index
	elif event is InputEventKey:
		button_object.text = OS.get_scancode_string((event as InputEventKey).scancode)
	else:
		button_object.text = "..."
	button_object.pressed = pressed
