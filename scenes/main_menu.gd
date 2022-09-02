extends Scene

onready var root_viewport := $"/root" as Root


func _ready() -> void:
	root_viewport.bg_changed(root_viewport.menu_bg)
	root_viewport.music.stop()

	## Comment
	var _bars_removed := root_viewport.remove_scene("Bars")


## Comment
func exit_button_pressed() -> void:
	get_tree().quit()


## Comment
func play_button_pressed() -> void:
	root_viewport.add_blackout(root_viewport.gameplay)


## Comment
func toggle_settings() -> void:
	if not root_viewport.remove_scene("SettingsPanel"):
		root_viewport.add_scene(root_viewport.settings_panel.instance(), name)
