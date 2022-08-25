extends CanvasItem

## Comment
signal hit_error_toggled

## Comment
signal late_early_changed

## Comment
signal offset_changed

## Comment
var _currently_changing := ""

## Comment
var _settings_save := false

onready var dropdown := $V/Resolution/Options as OptionButton
onready var fullscreen_toggle := $V/Resolution/Fullscreen/Toggle as CheckBox
onready var hit_error_toggle := $V/ExtraDisplays/HitError/Toggle as CheckBox
onready var late_early_drop := $V/ExtraDisplays/LateEarly/Options as OptionButton
onready var offset_text := $V/Offset/LineEdit as LineEdit
onready var taiclone := $"/root" as Root


func _ready() -> void:
	for key in taiclone.KEYS:
		_change_text(str(key))

	late_early_drop.add_item("Off")
	late_early_drop.add_item("Simple")
	late_early_drop.add_item("Advanced")
	late_early(taiclone.late_early_simple_display)
	hit_error(taiclone.hit_error)

	for i in taiclone.RESOLUTIONS.size():
		## Comment
		var item := str(taiclone.RESOLUTIONS[i]).split(",", false)

		if item.empty():
			dropdown.add_separator()

		else:
			dropdown.add_item("%s | %sx%s" % Array(item))

			## Comment
			var item_resolution := taiclone.item_resolution(item)

			dropdown.set_item_metadata(int(i), item_resolution)
			if item_resolution == OS.window_size:
				dropdown.select(int(i))

	toggle_fullscreen(OS.window_fullscreen)
	change_offset(str(taiclone.global_offset))
	_settings_save = true


func _input(event: InputEvent) -> void:
	if _currently_changing and (event is InputEventJoypadButton or event is InputEventKey):
		if _settings_save:
			taiclone.change_key(event, _currently_changing, true)
		_change_text(_currently_changing)
		_currently_changing = ""


## Comment
func button_pressed(type: String) -> void:
	_change_text(type, not _currently_changing)
	_currently_changing = "" if _currently_changing else type


## Comment
func change_offset(new_value: String) -> void:
	## Comment
	var new_offset := int(new_value)

	offset_text.text = str(new_offset) if new_offset else ""
	if _settings_save:
		taiclone.global_offset = new_offset
		emit_signal("offset_changed")
		taiclone.save_settings("change_offset")


## Comment
func change_res(index: int) -> void:
	taiclone.change_res(index)


## Comment
func hit_error(new_visible: bool) -> void:
	hit_error_toggle.pressed = new_visible
	if _settings_save:
		taiclone.hit_error = new_visible
		emit_signal("hit_error_toggled")
		taiclone.save_settings("hit_error")


## Comment
func late_early(new_value: int) -> void:
	late_early_drop.select(new_value)
	if _settings_save:
		taiclone.late_early_simple_display = new_value
		emit_signal("late_early_changed")
		taiclone.save_settings("late_early")


## Comment
func toggle_fullscreen(new_visible: bool) -> void:
	if _settings_save:
		taiclone.toggle_fullscreen(new_visible, true)

	fullscreen_toggle.pressed = new_visible
	for i in range(dropdown.get_item_count()):
		dropdown.set_item_disabled(i, new_visible)


## Comment
func toggle_settings() -> void:
	visible = not visible


## Comment
func _change_text(button: String, pressed := false) -> void:
	## Comment
	var event := Root.event(button)

	## Comment
	var button_object := get_node("V/Keybinds/%s/Button" % button) as Button

	button_object.text = "..." if pressed else "Joystick Button %s" % (event as InputEventJoypadButton).button_index if event is InputEventJoypadButton else OS.get_scancode_string((event as InputEventKey).scancode) if event is InputEventKey else ""
