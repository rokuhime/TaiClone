class_name SettingsPanel
extends Panel

var keychange_timeout: Timer
var movement_tween: Tween
var keychange_target := ""
var is_visible := false
@onready var player_name_edit := $ScrollContainer/VBoxContainer/Login/LineEdit
@onready var chart_path_changer: ChartPathChanger = $ScrollContainer/VBoxContainer/ChartPathChanger
@onready var keybind_list := $ScrollContainer/VBoxContainer/KeybindList

func _ready():
	chart_path_changer.refresh_paths()
	player_name_edit.text = Global.player_name
	
	if not is_visible:
		position.x = get_viewport_rect().size.x
	
	for key in Global.GAMEPLAY_KEYS:
		keychange_target = key
		change_key(key)

func _process(_delta):
	if position == Vector2(get_viewport_rect().size.x, 0) and visible == true:
		visible = false
	elif position != Vector2(get_viewport_rect().size.x, 0) and visible == false:
		visible = true

# i hate this and you should too. temporary fix to make the settings not so intrusive with inputs
func _input(event):
	if not (event is InputEventKey) or event.is_echo() or !event.is_pressed():
		return
	
	if event.keycode == KEY_ENTER and Global.focus_lock:
		await get_tree().process_frame
		Global.change_focus_state(false)

func _unhandled_input(event):
	if event is InputEventMouse or event.is_echo() or !event.is_pressed():
		return
	
	if event is InputEventWithModifiers:
		if event.keycode == KEY_O and event.ctrl_pressed:
			toggle_visible()
			return
	
	if not keychange_target.is_empty():
		change_input_action(keychange_target, event)

# toggle visibility of the panel with a lil sliding animation
func toggle_visible():
	is_visible = not is_visible
	
	if movement_tween:
		movement_tween.kill()
	
	movement_tween = Global.create_smooth_tween()
	movement_tween.tween_property(
		self, 
		"position:x", 
		get_viewport_rect().size.x - size.x if is_visible else get_viewport_rect().size.x, 
		0.5 )

func change_key(target := keychange_target):
	if keychange_target.is_empty():
		Global.change_focus_state(true)
		keychange_target = target
		keybind_list.get_node(target + "/Button").text = "..."
		
		# disconnecting signals sucks via code, so just delete the old and make a new
		if keychange_timeout != null:
			keychange_timeout.queue_free()
		
		# add timeout before it sets back to what it was
		keychange_timeout = Timer.new()
		add_child(keychange_timeout)
		keychange_timeout.timeout.connect(Callable(self, "change_key"))
		keychange_timeout.start(3)
	
	elif keychange_target == target:
		keybind_list.get_node(target + "/Button").text = InputMap.action_get_events(target)[0].as_text()
		
		keychange_target = ""
		if keychange_timeout:
			keychange_timeout.queue_free()
		await get_tree().process_frame
		Global.change_focus_state(false)

func change_input_action(input_name: String, new_binding: InputEvent, called_by_user := true):
	# ensure the keychange target is correct
	keychange_target = input_name
	
	if InputMap.action_get_events(input_name):
		InputMap.action_erase_events(input_name)
	
	InputMap.action_add_event(input_name, new_binding)
	change_key(keychange_target)
	
	if called_by_user:
		Global.save_settings()

func load_keybinds(keybinds) -> void:
	await ready
	for keybind in keybinds:
		change_input_action(keybind, keybinds[keybind], false)

func change_player_name(new_name: String) -> void:
	Global.player_name = new_name
	Global.save_settings()

func update_focus(is_focused := true) -> void:
	Global.change_focus_state(is_focused)
