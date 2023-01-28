extends TextureRect

var playing := false

onready var objectContainer := $HitTarget/ObjectContainer as Node
 
func activateObjects() -> void:
	for hitObject in objectContainer.get_children():
		hitObject.activate()
		#hitObject.apply_skin()

func moveObjects(timeCurrent) -> void:
	for hitObject in objectContainer.get_children():
		hitObject.move(rect_size.x, timeCurrent)
