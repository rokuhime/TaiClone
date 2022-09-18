extends Scene

onready var root_viewport := $"/root" as Root
onready var play_button := $Play as Clickable
onready var play_label := $Play/Label as Label
onready var edit_button := $Edit as Clickable
onready var edit_label := $Edit/Label as Label
onready var training_button := $Training as Clickable
onready var training_label := $Training/Label as Label
onready var options_button := $Options as Clickable
onready var options_label := $Options/Label as Label
onready var exit_button := $Exit as Clickable
onready var exit_label := $Exit/Label as Label


func _ready() -> void:
	Engine.target_fps = 120
	GlobalTools.send_signal(root_viewport, "clicked", options_button, "toggle_settings")
	apply_skin()
	play_button.texture = root_viewport.button_white
	play_button.background.texture = root_viewport.button_black
	play_label.text = "Play"
	edit_button.modulate = Color("a1a1a1")
	edit_button.texture = root_viewport.button_white
	edit_button.background.texture = root_viewport.button_black
	edit_label.text = "Edit"
	training_button.modulate = Color("a1a1a1")
	training_button.texture = root_viewport.button_white
	training_button.background.texture = root_viewport.button_black
	training_label.text = "Training"
	options_button.texture = root_viewport.button_white
	options_button.background.texture = root_viewport.button_black
	options_label.text = "Options"
	exit_button.texture = root_viewport.button_white
	exit_button.background.texture = root_viewport.button_black
	exit_label.text = "Exit"
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
