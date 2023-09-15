# for one shot sounds that automatically delete
# only really intended for use with things that may overlap other sounds, or things that spawn audio on deletion
extends AudioStreamPlayer2D

func ini(parent: Node, source: AudioStream, new_bus := "Master", position := Vector2.ZERO) -> void:
	# add to the given parent so it doesnt just dissapear into nothingness
	parent.add_child(self)
	# if a position is given, move itsself to that
	if position:
		global_position = position
	
	# set audio settings and play
	stream = source
	bus = new_bus
	play()

# immediately deletes self on ending the sound
func finish() -> void:
	queue_free()
