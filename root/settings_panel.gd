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
onready var left_kat_butt := $V/Settings/V/Keybinds/LeftKat/Button as Button
onready var left_don_butt := $V/Settings/V/Keybinds/LeftDon/Button as Button
onready var right_don_butt := $V/Settings/V/Keybinds/RightDon/Button as Button
onready var right_kat_butt := $V/Settings/V/Keybinds/RightKat/Button as Button
onready var dropdown := $V/Settings/V/Resolution/Options as OptionButton
onready var fullscreen_toggle := $V/Settings/V/Resolution/Fullscreen/Toggle as CheckBox
onready var offset_text := $V/Settings/V/Offset/LineEdit as SpinBox
onready var offset_slider := $V/Settings/V/HSlider as HSlider
onready var late_early_drop := $V/Settings/V/ExtraDisplays/LateEarly/Options as OptionButton
onready var hit_error_toggle := $V/Settings/V/ExtraDisplays/HitError/Toggle as CheckBox


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
	_settings_save = true
	_tween_position()


func _unhandled_input(event: InputEvent) -> void:
	if _currently_changing and (event is InputEventJoypadButton or event is InputEventKey):
		root_viewport.change_key(event, _currently_changing)
		_change_text(_currently_changing)
		_currently_changing = ""


## Called when a key-bind button is pressed.
## key ([String]): The key-bind that should be changed.
func button_pressed(key: String) -> void:
	_change_text(key, not _currently_changing)
	_currently_changing = "" if _currently_changing else key


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



## See [Scene].
func scene_removed() -> void:
	_tween_position()


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
func _tween_position() -> void:
	_position_tween = root_viewport.new_tween(_position_tween).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT).set_parallel()
	_active = not _active

	## Comment
	var _left_tween := _position_tween.tween_property(self, "margin_left", -rect_size.x if _active else 0.0, 1)

	## Comment
	var _right_tween := _position_tween.tween_property(self, "margin_right", 0.0 if _active else rect_size.x, 1)

	if not _active:
		GlobalTools.send_signal(self, "finished", _position_tween, "queue_free")
