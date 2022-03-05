extends Sprite

onready var stoopy = get_node("movingpoint")

func doTheThing(timing):
	stoopy.set_position(Vector2(timing * 1000, 0))
