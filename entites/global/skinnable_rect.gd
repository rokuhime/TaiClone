class_name SkinnableRect
extends TextureRect

@export var texture_name: String

func _init(new_texture_name):
	texture_name = new_texture_name

# returns if it was successful or not
func apply_skin(skin: SkinManager) -> void:
	if not texture_name:
		return
	
	var new_texture = skin.get_texture(texture_name)
	if not new_texture:
		return
	
	texture = new_texture
