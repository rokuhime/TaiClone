extends Panel

var keychange_timeout: Timer
var movement_tween: Tween

var gameplay_keys := ["LeftKat", "LeftDon", "RightDon", "RightKat"]
var keychange_target := ""
var is_visible := false

@onready var keybind_list := $ScrollContainer/VBoxContainer/KeybindList

func _ready():
	load_settings()
	
	if not is_visible:
		position.x = get_viewport_rect().size.x
	
	for key in gameplay_keys:
		keychange_target = key
		change_key(key)

func _process(delta):
	if position == Vector2(get_viewport_rect().size.x, 0) and visible == true:
		visible = false
	elif position != Vector2(get_viewport_rect().size.x, 0) and visible == false:
		visible = true

func _unhandled_input(event):
	if event is InputEventMouseMotion or event.is_echo() or !event.is_pressed():
		return
	
	if event is InputEventWithModifiers:
		if event.keycode == KEY_O and event.ctrl_pressed:
			toggle_visible()
			return
	
	if not keychange_target.is_empty():
		change_input_action(keychange_target, event)

func toggle_visible():
	is_visible = not is_visible
	
	if movement_tween:
		movement_tween.kill()
	
	movement_tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	movement_tween.tween_property(
		self, 
		"position:x", 
		get_viewport_rect().size.x - size.x if is_visible else get_viewport_rect().size.x, 
		0.5 )

func change_key(target := keychange_target):
	if keychange_target.is_empty():
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

func change_input_action(input_name: String, new_binding: InputEvent):
	# ensure the keychange target is correct
	keychange_target = input_name
	
	if InputMap.action_get_events(input_name):
		InputMap.action_erase_events(input_name)
	
	InputMap.action_add_event(input_name, new_binding)
	change_key(keychange_target)
	save_settings()

func save_settings() -> void:
	print("SettingsPanel: Saving config...")
	var config_file := ConfigFile.new()
	
	for key in gameplay_keys:
		config_file.set_value("Keybinds", key, InputMap.action_get_events(key)[0])
	
	var err = config_file.save("user://settings.cfg")
	if err != OK:
		print("SettingsPanel: Config failed to save with code ", err)
		return
	print("SettingsPanel: Config saved!")

func load_settings() -> void:
	var config_file := ConfigFile.new()
	var err = config_file.load("user://settings.cfg")
	if err != OK:
		print("SettingsPanel: Config failed to load at user://settings.cfg with code ", err)
		return
	
	var keys = config_file.get_section_keys("Keybinds")
	for key in keys:
		var keybind = config_file.get_value("Keybinds", key, null)
		if keybind:
			change_input_action(key, keybind)
