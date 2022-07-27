extends HBoxContainer

# this script stinks. gonna become obsolete when i get actual good settings going w

onready var chartLoader = get_node("../../../../../ChartLoader")

onready var offsetText = get_node("LineEdit")
onready var objectContainer = get_node("../../../../../BarRight/HitPointOffset/ObjectContainers")

# Called when the node enters the scene tree for the first time.
func _ready():
	offsetText.connect("text_entered", self, "changeOffset")
	offsetText.text = str($"/root/Gameplay".global_offset)

func changeOffset(text):
	var offset = float(text);
	if (offset != null):
		offset /= 1000
		$"/root/Gameplay".global_offset = offset
	print($"/root/Gameplay".global_offset)
	
	#i dont know. it just works
	objectContainer.rect_position = Vector2($"/root/Gameplay".global_offset * -775, 0)
