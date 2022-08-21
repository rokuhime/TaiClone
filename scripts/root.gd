class_name Root
extends Viewport

var acc_timing: float
var global_offset: float
var inacc_timing: float
var skin: SkinManager


func _init() -> void:
	acc_timing = 0.06
	global_offset = 0
	inacc_timing = 0.145
	skin = SkinManager.new()


func bg_changed(newtexture: Texture, newmodulate := Color.white) -> void:
	var background := get_node("Background") as TextureRect
	background.modulate = newmodulate
	background.texture = newtexture


# Stop a previous tween and return the new tween to use going forward.
static func new_tween(old_tween: SceneTreeTween, node: Node) -> SceneTreeTween:
	if old_tween.is_valid():
		old_tween.kill()

	return node.create_tween()
