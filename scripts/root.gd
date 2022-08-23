class_name Root
extends Viewport

## Comment
var acc_timing: float

## Comment
var global_offset: float

## Comment
var inacc_timing: float

## Comment
var skin: SkinManager


func _init() -> void:
	acc_timing = 0.06
	global_offset = 0
	inacc_timing = 0.145
	skin = SkinManager.new()


## Comment
func bg_changed(newtexture: Texture, newmodulate := Color.white) -> void:
	## Comment
	var background := get_node("Background") as TextureRect

	background.modulate = newmodulate
	background.texture = newtexture


## Comment
static func new_tween(old_tween: SceneTreeTween, node: Node) -> SceneTreeTween:
	if old_tween.is_valid():
		old_tween.kill()

	return node.create_tween()
