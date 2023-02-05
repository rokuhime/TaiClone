class_name Track
extends TextureRect

var playing := false

onready var objectContainer := $HitTarget/ObjectContainer as Node
 
func activateObjects() -> void:
	for hitObject in objectContainer.get_children():
		hitObject.activate()
		#hitObject.apply_skin()

func moveObjects(timeCurrent) -> void:
	for hitObject in objectContainer.get_children():
		# uses the tracks horizontal size as first variable, so it adapts being visible to that
		# saves frames
		hitObject.move(rect_size.x, timeCurrent)
