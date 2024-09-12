class_name SettingsPanel
extends Panel

@onready var player_name_edit := $ScrollContainer/VBoxContainer/Login/LineEdit
@onready var chart_path_changer: ChartPathChanger = $ScrollContainer/VBoxContainer/ChartPathChanger
@onready var keybind_list := $ScrollContainer/VBoxContainer/KeybindList
@onready var skin_vbox := $ScrollContainer/VBoxContainer/Skin

var enabled := false
var movement_tween: Tween
var size_tween: Tween

var keychange_timeout: Timer
var keychange_target := ""

# -------- system --------

func _ready() -> void:
	# start tucked into right side
	position.x = get_viewport_rect().size.x
	
	# load existing settings
	chart_path_changer.refresh_paths()
	player_name_edit.text = Global.player_name
	$ScrollContainer/VBoxContainer/Etc/DisplayVersion.button_pressed = Global.display_version
	$ScrollContainer/VBoxContainer/Etc/DisplayClockInfo.button_pressed = Global.display_clocktiming_info
	$ScrollContainer/VBoxContainer/Etc/BarlineLimit/Checkbox.button_pressed = Global.limit_barlines
	
	# check skin. if its valid (file_path exists), set data. otherwise, assume its default
	if Global.current_skin.file_path:
		skin_vbox.get_node("SkinInfo").text = "[font_size=16][center]%s - %s [color=777777](%s)\n%s" % (Global.current_skin.info + [Global.current_skin.file_path])
	else:
		var info = SkinManager.new().info
		info.pop_back()
		skin_vbox.get_node("SkinInfo").text = "[font_size=16][center]%s - %s" % info
	
	set_keybinds_to_default() 
	
	await Global.get_root().ready
	var navbars = Global.get_root().get_node("NavigationBars")
	navbars.on_toggle.connect(scale_for_navbars.bind(navbars))

func _process(_delta) -> void:
	if position == Vector2(get_viewport_rect().size.x, 0) and visible == true:
		visible = false
	elif position != Vector2(get_viewport_rect().size.x, 0) and visible == false:
		visible = true

func _unhandled_input(event) -> void:
	if event is InputEventMouse or event.is_echo() or !event.is_pressed():
		return
	
	# ctrl + o options hotkey
	if event is InputEventWithModifiers:
		if event.keycode == KEY_O and event.ctrl_pressed:
			toggle_visible()
			return
	
	if not keychange_target.is_empty():
		change_input_action(keychange_target, event)

# -------- visual --------

# toggle visibility of the panel with a lil sliding animation
func toggle_visible() -> void:
	enabled = not enabled
	
	if movement_tween:
		movement_tween.kill()
	
	movement_tween = Global.create_smooth_tween(
		self, 
		"position:x", 
		get_viewport_rect().size.x - size.x if enabled else get_viewport_rect().size.x, 
		0.5 
	)

func scale_for_navbars(navbar_enabled: bool, navbars: Control) -> void:
	# change scale to give space to navbars
	var navbar_size = navbars.get_node("Top").size.y + navbars.get_node("Bottom").size.y
	
	if size_tween:
		size_tween.kill()
	size_tween = Global.create_smooth_tween(
		self, 
		"size:y", 
		get_viewport_rect().size.y - navbar_size if navbar_enabled else get_viewport_rect().size.y, 
		0.5 
	)
	
	if movement_tween:
		movement_tween.kill()
	
	var new_position := Vector2(
		get_viewport_rect().size.x - size.x if enabled else get_viewport_rect().size.x, 
		navbars.get_node("Top").size.y if navbar_enabled else 0
	)
	movement_tween = Global.create_smooth_tween(
		self, 
		"position", 
		new_position, 
		0.5 
	)

# -------- keybind changing --------

func get_changeable_binds() -> Array:
	var binds := []
	for node in $ScrollContainer/VBoxContainer/KeybindList.get_children():
		if node is HBoxContainer:
			binds.append(node.name)
	
	return binds

# sets keybind button text to the current binding
func set_keybinds_to_default() -> void:
	for bind in get_changeable_binds():
		keychange_target = bind
		change_key(bind)

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
		
		return
	
	elif keychange_target == target:
		keybind_list.get_node(target + "/Button").text = InputMap.action_get_events(target)[0].as_text()
		
		keychange_target = ""
		if keychange_timeout:
			keychange_timeout.queue_free()
		
		await get_tree().process_frame
		Global.change_focus()

# changes corresponding InputMap event to new_binding
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
		if InputMap.action_get_events(keybind):
			change_input_action(keybind, keybinds[keybind], false)

# -------- setting vars --------

func set_skin(directory: String) -> void:
	Global.current_skin = SkinManager.new(directory)
	await get_tree().process_frame
	
	var skin_info = Global.current_skin.info
	skin_info.append(Global.current_skin.file_path)
	skin_vbox.get_node("SkinInfo").text = "[font_size=16][center]%s - %s [color=777777](%s)\n%s" % skin_info
	
	Global.save_settings()

func change_player_name(new_name: String) -> void:
	Global.player_name = new_name
	Global.save_settings()
	Global.change_focus()

func toggle_oneoff(new_value: bool, index: int) -> void:
	match index:
		0: # version info
			Global.display_version = new_value
		1: # clocktiming info
			Global.display_clocktiming_info = new_value
		2: # barline limit
			Global.limit_barlines = new_value

# -------- etc --------

# bridge to connect signals from objects on the SettingsPanel to Global
func update_focus(new_target: Node) -> void:
	Global.change_focus_state(new_target)

# attempts to open converted charts location, and prints filepath in console
func open_converted_charts_folder() -> void:
	OS.shell_open(ProjectSettings.globalize_path(Global.CONVERTED_CHART_FOLDER))
	Global.push_console("SettingsPanel", "ConvertedCharts directory: \n%s" % ProjectSettings.globalize_path(Global.CONVERTED_CHART_FOLDER))
