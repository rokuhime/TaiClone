class_name ModIcon
extends Control

var mod_id := -1
var enabled := false
var color_tween: Tween

func _ready():
	update_visual()

func update_visual() -> void:
	# get graphic info from SkinManager using mod_id
	match mod_id:
		ModPanel.MOD_TYPES.AUTO:
			$ColorRect.color = Color("7aa0ff")
			$ColorRect/Label.text = "Auto"
		
		ModPanel.MOD_TYPES.BARLINE_AUDIO:
			$ColorRect.color = Color("db9758")
			$ColorRect/Label.text = "Barline Audio"
	
	if color_tween:
		color_tween.kill()
	color_tween = Global.create_smooth_tween(
		self, 
		"modulate", 
		Color.WHITE if enabled else Color(0.5,0.5,0.5), 
		0.3
	)

func toggle_enabled(new_enabled: bool) -> void:
	enabled = new_enabled
	update_visual()

func _on_gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.is_echo() or event.button_index != MOUSE_BUTTON_LEFT or !event.is_pressed():
			return
		toggle_enabled(!enabled)
