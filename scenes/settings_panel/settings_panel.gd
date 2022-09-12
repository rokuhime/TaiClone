extends Scene

## The list of selectable resolutions.
const RESOLUTIONS := ["16:9,1920,1080", "16:9,1280,720", "16:9,1024,576", "", "4:3,1440,1080", "4:3,1024,768", "", "5:4,1280,1024", "5:4,1025,820"]

## Comment
var _position_tween := SceneTreeTween.new()

## The key-bind that's currently being changed.
var _currently_changing := ""

## Comment
var _active := false

## Whether or not settings should be saved.
var _settings_save := false

onready var root_viewport := $"/root" as Root
onready var left_kat_butt := $H/Menu/Settings/V/Keybinds/LeftKat/Button as Button
onready var left_don_butt := $H/Menu/Settings/V/Keybinds/LeftDon/Button as Button
onready var right_don_butt := $H/Menu/Settings/V/Keybinds/RightDon/Button as Button
onready var right_kat_butt := $H/Menu/Settings/V/Keybinds/RightKat/Button as Button
onready var dropdown := $H/Menu/Settings/V/Resolution/Options as OptionButton
onready var fullscreen_toggle := $H/Menu/Settings/V/Resolution/Fullscreen/Toggle as CheckBox
onready var offset_text := $H/Menu/Settings/V/Offset/LineEdit as SpinBox
onready var offset_slider := $H/Menu/Settings/V/HSlider as HSlider
onready var late_early_drop := $H/Menu/Settings/V/ExtraDisplays/LateEarly/Options as OptionButton
onready var hit_error_toggle := $H/Menu/Settings/V/ExtraDisplays/HitError/Toggle as CheckBox
onready var game_path_text := $H/Menu/Settings/V/GamePathText as Label


func _ready() -> void:
	for key in Root.KEYS:
		_change_text(str(key))

	late_early_drop.add_item("Off")
	late_early_drop.add_item("Simple")
	late_early_drop.add_item("Advanced")
	late_early(root_viewport.late_early_simple_display)
	hit_error_func(root_viewport.hit_error)
	for i in RESOLUTIONS.size():
		## A resolution in the format: ratio, width, height.
		var resolution := str(RESOLUTIONS[i]).split(",", false)

		if resolution.empty():
			dropdown.add_separator()

		else:
			dropdown.add_item("%s | %sx%s" % Array(resolution))
			if _item_resolution(resolution) == OS.window_size:
				dropdown.select(int(i))

	toggle_fullscreen(OS.window_fullscreen)
	change_offset(root_viewport.global_offset)
	change_game_path(root_viewport.game_path, false)
	_settings_save = true
	_tween_position()


func _unhandled_input(event: InputEvent) -> void:
	if _currently_changing and (event is InputEventJoypadButton or event is InputEventKey):
		root_viewport.change_key(event, _currently_changing)
		_change_text(_currently_changing)
		_currently_changing = ""


## Comment
func back_button_pressed() -> void:
	var _removed := root_viewport.remove_scene("SettingsPanel")


## Called when a key-bind button is pressed.
## key ([String]): The key-bind that should be changed.
func button_pressed(key: String) -> void:
	_change_text(key, not _currently_changing)
	_currently_changing = "" if _currently_changing else key


## Comment
func change_game_path(new_text: String, move_folder := true) -> void:
	if move_folder:
		## Comment
		var directory := Directory.new()

		assert(not directory.rename(root_viewport.game_path, new_text), "Unable to move game directory.")
		assert(not directory.make_dir_recursive(root_viewport.game_path), "Unable to recreate old game path directory.")
		if directory.dir_exists(new_text.plus_file("logs")):
			assert(not OS.move_to_trash(new_text.plus_file("logs")), "Unable to remove logs folder.")

		## Comment
		var storage_file := File.new()

		assert(not storage_file.open(Root.STORAGE_PATH, File.WRITE), "Unable to write storage.ini file.")
		storage_file.store_string(new_text)
		storage_file.close()
		if root_viewport.songs_folder == root_viewport.game_path:
			root_viewport.songs_folder = new_text

		root_viewport.game_path = new_text

	game_path_text.text = new_text


## Called when [member offset_text] changes.
## new_offset ([float]): The new value entered.
func change_offset(new_offset: float) -> void:
	offset_slider.value = new_offset
	offset_text.value = new_offset
	if _settings_save:
		root_viewport.global_offset = int(new_offset)
		root_viewport.save_settings()


## Called when a different resolution is selected.
## index ([int]): The index of the resolution in [member RESOLUTIONS].
func change_res(index: int) -> void:
	root_viewport.res_changed(_item_resolution(str(RESOLUTIONS.slice(index, index)[0]).split(",", false)))


## Comment
func change_songs_button_pressed() -> void:
	_file_dialog(self, root_viewport.songs_folder, "change_songs_folder")


## Comment
func change_songs_folder(new_text: String) -> void:
	root_viewport.songs_folder = new_text

	## Comment
	var songs_folder := root_viewport.taiclone_songs_folder()

	if Directory.new().dir_exists(songs_folder):
		assert(not OS.move_to_trash(songs_folder), "Unable to remove songs folder.")

	_import_songs(songs_folder, new_text)
	root_viewport.save_settings()
	root_viewport.add_blackout(root_viewport.song_select)


## Comment
func game_path_button_pressed() -> void:
	_file_dialog(self, root_viewport.game_path, "change_game_path")


## Called when [member hit_error_toggle] is toggled.
## new_visible ([bool]): Whether or not the hit error bar should be visible.
func hit_error_func(new_visible: bool) -> void:
	hit_error_toggle.pressed = new_visible
	if _settings_save:
		root_viewport.hit_error_toggled(new_visible)


## Called when a new timing indicator format is selected,
## new_value ([int]): The index of [member late_early_drop] chosen.
func late_early(new_value: int) -> void:
	late_early_drop.select(new_value)
	if _settings_save:
		root_viewport.late_early(new_value)


## Comment
func remove_skin() -> void:
	root_viewport.change_skin()



## See [Scene].
func scene_removed() -> void:
	_tween_position()


## Comment
func skin_button_pressed() -> void:
	_file_dialog(root_viewport, root_viewport.skin_path, "change_skin")


## Called when [member fullscreen_toggle] is toggled.
## new_visible ([bool]): Whether or not the window should be fullscreen.
func toggle_fullscreen(new_visible: bool) -> void:
	fullscreen_toggle.pressed = new_visible
	for i in range(dropdown.get_item_count()):
		dropdown.set_item_disabled(i, new_visible)

	if _settings_save:
		root_viewport.toggle_fullscreen(new_visible)


## Comment
static func _item_resolution(item: Array) -> Vector2:
	return Vector2(int(item[1]), int(item[2]))


## Changes the label of a key-bind button.
## key ([String]): The key-bind being changed.
## was_pressed ([bool]): Whether or not the button was pressed.
func _change_text(key: String, was_pressed := false) -> void:
	## Comment
	var button_obj: Button

	match key:
		"LeftDon":
			button_obj = left_don_butt

		"LeftKat":
			button_obj = left_kat_butt

		"RightDon":
			button_obj = right_don_butt

		"RightKat":
			button_obj = right_kat_butt

		_:
			push_warning("Unknown keybind button.")
			return

	## The action associated with this key-bind.
	var event := GlobalTools.get_event(key)

	button_obj.text = "..." if was_pressed else "Joystick Button %s" % (event as InputEventJoypadButton).button_index if event is InputEventJoypadButton else OS.get_scancode_string((event as InputEventKey).scancode) if event is InputEventKey else ""


## Comment
func _file_dialog(signal_target: Node, open_dir: String, method: String) -> void:
	## Comment
	var file_dialog := FileDialog.new()

	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.mode = FileDialog.MODE_OPEN_DIR
	file_dialog.current_dir = open_dir
	file_dialog.show_hidden_files = true
	file_dialog.window_title = ""
	GlobalTools.send_signal(signal_target, "dir_selected", file_dialog, method)
	GlobalTools.send_signal(file_dialog, "popup_hide", file_dialog, "queue_free")
	root_viewport.add_scene(file_dialog, "VolumeControl")
	file_dialog.popup_centered_ratio(1)
	file_dialog.set_anchors_and_margins_preset(Control.PRESET_WIDE)


## Comment
func _import_songs(songs_folder: String, folder_path: String) -> void:
	## Comment
	var directory := Directory.new()

	assert(not directory.open(folder_path), "Unable to open songs folder.")
	assert(not directory.list_dir_begin(true), "Unable to read songs folder.")
	while true:
		## Comment
		var file_name := directory.get_next()

		if not file_name:
			return

		if directory.current_is_dir():
			_import_songs(songs_folder, folder_path.plus_file(file_name))

		else:
			ChartLoader.load_chart(songs_folder.plus_file(folder_path.trim_prefix(root_viewport.songs_folder)).plus_file(file_name.get_basename() + ".fus"), folder_path.plus_file(file_name))


## Comment
func _tween_position() -> void:
	_position_tween = root_viewport.new_tween(_position_tween).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT).set_parallel()
	_active = not _active

	## Comment
	var _left_tween := _position_tween.tween_property(self, "margin_left", -rect_size.x if _active else 0.0, 1)

	## Comment
	var _right_tween := _position_tween.tween_property(self, "margin_right", 0.0 if _active else rect_size.x, 1)

	if not _active:
		GlobalTools.send_signal(self, "finished", _position_tween, "queue_free")
