class_name SettingsPanel
extends CanvasItem

## The list of selectable resolutions.
const RESOLUTIONS := ["16:9,1920,1080", "16:9,1280,720", "16:9,1024,576", "", "4:3,1440,1080", "4:3,1024,768", "", "5:4,1280,1024", "5:4,1025,820"]

## The key-bind that's currently being changed.
var _currently_changing := ""

## Whether or not settings should be saved.
var _settings_save := false

onready var dropdown := $V/Resolution/Options as OptionButton
onready var fullscreen_toggle := $V/Resolution/Fullscreen/Toggle as CheckBox
onready var hit_error_toggle := $V/ExtraDisplays/HitError/Toggle as CheckBox
onready var late_early_drop := $V/ExtraDisplays/LateEarly/Options as OptionButton
onready var offset_text := $V/Offset/LineEdit as LineEdit
onready var root_viewport := $"/root" as Root


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
			if Root.item_resolution(resolution) == OS.window_size:
				dropdown.select(int(i))

	toggle_fullscreen(OS.window_fullscreen)
	change_offset(str(root_viewport.global_offset))
	_settings_save = true


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
## new_text ([String]): The new value entered.
func change_offset(new_text: String) -> void:
	if new_text == "-":
		return

	## The position of the cursor in [member offset_text].
	var text_position := offset_text.caret_position

	## The new offset value that's being applied.
	var new_offset := int(new_text)

	offset_text.text = str(new_offset) if new_offset else ""
	offset_text.caret_position = text_position
	if _settings_save:
		root_viewport.offset_difference(new_offset - root_viewport.global_offset)
		root_viewport.global_offset = new_offset
		root_viewport.save_settings("change_offset")


## Called when a different resolution is selected.
## index ([int]): The index of the resolution in [member RESOLUTIONS].
func change_res(index: int) -> void:
	root_viewport.res_changed(Root.item_resolution(str(RESOLUTIONS.slice(index, index)[0]).split(",", false)))


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


## Called when [member fullscreen_toggle] is toggled.
## new_visible ([bool]): Whether or not the window should be fullscreen.
func toggle_fullscreen(new_visible: bool) -> void:
	fullscreen_toggle.pressed = new_visible
	for i in range(dropdown.get_item_count()):
		dropdown.set_item_disabled(i, new_visible)

	if _settings_save:
		root_viewport.toggle_fullscreen(new_visible)


## Changes the label of a key-bind button.
## key ([String]): The key-bind being changed.
## was_pressed ([bool]): Whether or not the button was pressed.
func _change_text(key: String, was_pressed := false) -> void:
	## The action associated with this key-bind.
	var event := Root.get_event(key)

	(get_node("V/Keybinds/%s/Button" % key) as Button).text = "..." if was_pressed else "Joystick Button %s" % (event as InputEventJoypadButton).button_index if event is InputEventJoypadButton else OS.get_scancode_string((event as InputEventKey).scancode) if event is InputEventKey else ""
