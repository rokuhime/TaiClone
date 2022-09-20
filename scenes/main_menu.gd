extends Scene

onready var root_viewport := $"/root" as Root
onready var options_button := $Options


func _ready() -> void:
	Engine.target_fps = 120
	GlobalTools.send_signal(root_viewport, "clicked", options_button, "toggle_settings")
	root_viewport.music.stop()
	root_viewport.remove_scene("Bars")


## Applies the [member root_viewport]'s [SkinManager] to this [Node]. This method is seen in all [Node]s in the "Skinnables" group.
func apply_skin() -> void:
	root_viewport.bg_changed(root_viewport.skin.menu_bg)


## Comment
func exit_button_pressed() -> void:
	get_tree().quit()


## Comment
func play_button_pressed() -> void:
	root_viewport.add_blackout(root_viewport.song_select)
