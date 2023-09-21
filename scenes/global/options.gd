extends ColorRect

var toggled := false
@onready var input_section := $ScrollContainer/Contents/Input
var keychange_target := ""

# Called when the node enters the scene tree for the first time.
func _ready():
	for input in input_section.get_children():
		if input.name == "SectionTitle":
			continue
		
		# set button text to correspoding input
		input.get_node("Button").text = InputMap.action_get_events(input.name)[0].as_text()
		input.get_node("Button").pressed.connect(change_key.bind(input.name))
		pass

func _unhandled_input(event) -> void:
	if keychange_target != "" and event.is_pressed() and (event is InputEventKey or event is InputEventJoypadButton):
		change_key(event)
		return
	
	elif event is InputEventKey:
		if event.keycode == KEY_O and event.ctrl_pressed and event.pressed:
			toggled = not toggled
			visible = toggled

func change_key(target):
	if target is String or target is StringName:
		if keychange_target == "":
			keychange_target = target
			input_section.get_node(target + "/Button").text = "..."
		
		elif keychange_target == target:
			keychange_target = ""
			input_section.get_node(target + "/Button").text = InputMap.action_get_events(target)[0].as_text()
	
	elif target is InputEvent:
		input_section.get_node(keychange_target + "/Button").text = target.as_text()
		
		InputMap.action_erase_events(keychange_target)
		InputMap.action_add_event(keychange_target, target)
		
		keychange_target = ""
