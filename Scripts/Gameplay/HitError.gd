extends Control

onready var avgHit = get_node("AverageHit")
onready var middleMarker = get_node("MiddleMarker")
onready var hitPoints = get_node("HitPoints")

var hitPositions = []

func newMarker(type, timing):
	var newMarker = middleMarker.duplicate()
	hitPoints.add_child(newMarker)
	
	var markerColour: Color;
	print(type)
	match type:
		"accurate": markerColour = skin.AccurateColour
		"inaccurate": markerColour = skin.InaccurateColour
		"miss": markerColour = skin.MissColour
	newMarker.modulate = markerColour;
	
	newMarker.rect_position = Vector2(timing * self.rect_size.x * 3.2 + (self.rect_size.x / 2), 0)
	
	hitPositions.push_back(newMarker.rect_position.x)
	if(hitPositions.size() > 25): hitPositions.remove(0)
	
	fadeOutMarkers()
	changeAvgHitPos()

func fadeOutMarkers():
	#print(hitPoints.get_child_count(), " markers")
	var i: int = 0
	for marker in hitPoints.get_children():
		if i >= 25: 
			hitPoints.get_child(0).queue_free()
		else:
			var markerAlpha: float = float(i) / 25
			hitPoints.get_child(i).self_modulate = Color(1,1,1,markerAlpha)
		i += 1

func changeAvgHitPos():
	var avg: float = 0
	for hp in hitPositions:
		avg += hp - (self.rect_size.x / 2) + 187
	avg = avg / hitPositions.size()
	
	avgHit.rect_position = Vector2(avg, 18)
