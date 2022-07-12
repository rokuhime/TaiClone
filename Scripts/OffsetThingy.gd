extends HBoxContainer

# this script stinks. gonna become obsolete when i get actual good settings going w

onready var offsetText = get_node("LineEdit")

# Called when the node enters the scene tree for the first time.
func _ready():
	offsetText.connect("text_entered", self, "changeOffset")
	offsetText.text = str(settings.globalOffset)

func changeOffset(text):
	var offset = float(text);
	if (offset != null):
		offset /= 1000
		settings.globalOffset = offset
