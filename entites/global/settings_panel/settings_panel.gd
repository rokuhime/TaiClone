extends Panel

var keychange_timeout: Timer
var movement_tween: Tween
var keychange_target := ""
var is_visible := false

@onready var chart_path_changer: ChartPathChanger = $ScrollContainer/VBoxContainer/ChartPathChanger
@onready var keybind_list := $ScrollContainer/VBoxContainer/KeybindList

func _ready():
	load_settings()
	chart_path_changer.refresh_paths()
	
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

func _unhandled_input(event):
	if event is InputEventMouse or event.is_echo() or !event.is_pressed():
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

func change_input_action(input_name: String, new_binding: InputEvent, called_by_user := true):
	# ensure the keychange target is correct
	keychange_target = input_name
	
	if InputMap.action_get_events(input_name):
		InputMap.action_erase_events(input_name)
	
	InputMap.action_add_event(input_name, new_binding)
	change_key(keychange_target)
	
	if called_by_user:
		save_settings()

func save_settings() -> void:
	var config_file := ConfigFile.new()
	
	config_file.set_value("General", "ChartPaths", Global.chart_paths)
	
	for bus_index in AudioServer.bus_count:
		config_file.set_value("Audio", AudioServer.get_bus_name(bus_index), db_to_linear(AudioServer.get_bus_volume_db(bus_index)))
	
	for key in Global.GAMEPLAY_KEYS:
		config_file.set_value("Keybinds", key, InputMap.action_get_events(key)[0])
	
	# save file
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
	
	Global.chart_paths = config_file.get_value("General", "ChartPaths", null)
	
	var audio_settings = config_file.get_section_keys("Audio")
	for setting in audio_settings:
		var bus_volume = config_file.get_value("Audio", setting, 1)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(setting), linear_to_db(bus_volume))
		
	get_tree().get_first_node_in_group("VolumeControl").update_bar()
	
	var keys = config_file.get_section_keys("Keybinds")
	for key in keys:
		var keybind = config_file.get_value("Keybinds", key, null)
		if keybind:
			change_input_action(key, keybind, false)
	print("SettingsPanel: Config loaded!")
