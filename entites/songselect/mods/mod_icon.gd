class_name ModIcon
extends Control

var mod_id := -1
var enabled := false

var color_tween: Tween
var opacity_tween: Tween
var y_pos_tween: Tween

signal mod_toggled(mod_id: int, is_enabled: bool)

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
	mod_toggled.emit(mod_id, enabled)

func _on_gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.is_echo() or event.button_index != MOUSE_BUTTON_LEFT or !event.is_pressed():
			return
		toggle_enabled(!enabled)

func enable_as_card() -> void:
	enabled = true
	update_visual()
	
	if opacity_tween:
		opacity_tween.kill()
	opacity_tween = Global.create_smooth_tween(self, "modulate:a", 1.0, 0.3, 0.0)
	if y_pos_tween:
		y_pos_tween.kill()
	y_pos_tween = Global.create_smooth_tween(self, "position:y", 0.0, 0.3, 40.0)

func disable_as_card() -> void:
	enabled = false
	
	opacity_tween = Global.create_smooth_tween(self, "modulate:a", 0.0, 0.3, 1.0)
	y_pos_tween = Global.create_smooth_tween(self, "position:y", 40.0, 0.3, 0.0)
	
	y_pos_tween.finished.connect(queue_free)
