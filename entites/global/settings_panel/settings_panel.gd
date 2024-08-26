class_name SettingsPanel
extends Panel

@onready var player_name_edit := $ScrollContainer/VBoxContainer/Login/LineEdit
@onready var chart_path_changer: ChartPathChanger = $ScrollContainer/VBoxContainer/ChartPathChanger
@onready var keybind_list := $ScrollContainer/VBoxContainer/KeybindList
@onready var barline_limit_checkbox := $ScrollContainer/VBoxContainer/Etc/BarlineLimitCheckbox
@onready var skin_vbox := $ScrollContainer/VBoxContainer/Skin

var is_visible := false
var movement_tween: Tween

var keychange_timeout: Timer
var keychange_target := ""

# -------- system -------

func _ready() -> void:
	chart_path_changer.refresh_paths()
	player_name_edit.text = Global.player_name
	barline_limit_checkbox.button_pressed = Global.limit_barlines
	
	if Global.current_skin.file_path:
		var info = Global.current_skin.info
		info.append(Global.current_skin.file_path)
		skin_vbox.get_node("SkinInfo").text = "[font_size=16][center]%s - %s [color=777777](%s)\n%s" % info
	else:
		skin_vbox.get_node("SkinInfo").text = "[font_size=16][center]%s - %s [color=777777](%s)" % SkinManager.new().info
	
	if not is_visible:
		position.x = get_viewport_rect().size.x
	
	for key in Global.GAMEPLAY_KEYS:
		keychange_target = key
		change_key(key)

func _process(_delta) -> void:
	if position == Vector2(get_viewport_rect().size.x, 0) and visible == true:
		visible = false
	elif position != Vector2(get_viewport_rect().size.x, 0) and visible == false:
		visible = true

func _unhandled_input(event) -> void:
	if event is InputEventMouse or event.is_echo() or !event.is_pressed():
		return
	
	if event is InputEventWithModifiers:
		if event.keycode == KEY_O and event.ctrl_pressed:
			toggle_visible()
			return
	
	if not keychange_target.is_empty():
		change_input_action(keychange_target, event)

# -------- keybind changing -------

func change_key(target := keychange_target) -> void:
	if keychange_target.is_empty():
		Global.change_focus(keybind_list)
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
		Global.change_focus()

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

# -------- etc -------

func set_skin(directory: String) -> void:
	Global.current_skin = SkinManager.new(directory)
	await get_tree().process_frame
	
	var skin_info = Global.current_skin.info
	skin_info.append(Global.current_skin.file_path)
	skin_vbox.get_node("SkinInfo").text = "[font_size=16][center]%s - %s [color=777777](%s)\n%s" % skin_info
	
	Global.save_settings()

# toggle visibility of the panel with a lil sliding animation
func toggle_visible() -> void:
	is_visible = not is_visible
	
	if movement_tween:
		movement_tween.kill()
	
	movement_tween = Global.create_smooth_tween(
		self, 
		"position:x", 
		get_viewport_rect().size.x - size.x if is_visible else get_viewport_rect().size.x, 
		0.5 
	)

func change_player_name(new_name: String) -> void:
	Global.player_name = new_name
	Global.save_settings()
	Global.change_focus()

# bridge to connect signals from objects on the SettingsPanel to Global
func update_focus(new_target: Node) -> void:
	Global.change_focus_state(new_target)

func open_converted_charts_folder() -> void:
	OS.shell_open(ProjectSettings.globalize_path("user://ConvertedCharts"))
	Global.push_console("SettingsPanel", "Using Linux? Your file manager probably didnt open! ConvertedCharts is located here: \n%s" % ProjectSettings.globalize_path("user://ConvertedCharts"), )

func toggle_barline_limit(new_value: bool) -> void:
	Global.limit_barlines = new_value
