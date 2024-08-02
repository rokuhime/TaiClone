extends Control

@onready var splash_label := $VBoxContainer/Splash

func _ready() -> void:
	splash_label.text = get_splash()

func menu_button_pressed(index: int) -> void:
	match index:
		0: # play
			Global.get_root().change_state(Root.GAMESTATE.SONG_SELECT)
		1: # settings
			get_tree().get_first_node_in_group("SettingsPanel").toggle_visible()

# loads splash.txt in values, returns a random line from it
func get_splash() -> String:
	var splash_file := FileAccess.open("res://values/splash.txt", FileAccess.READ)
	var splashes := []
	
	while splash_file.get_position() < splash_file.get_length():
		var line = splash_file.get_line().strip_edges()
		splashes.append(line)
	return splashes.pick_random()
