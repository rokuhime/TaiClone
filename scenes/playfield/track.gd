extends TextureRect

var playing := false
onready var objectContainer := $HitTarget/ObjectContainer as Node
var timeCurrent := 0.0
var timeBegin := 0.0

func changeChartPlayback():
	if not playing:
		timeBegin += Time.get_ticks_usec() / 1000000.0 + AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()

		for hitObject in objectContainer.get_children():
			hitObject.activate()
			
	playing = not playing


func _process(_delta):
	if not playing:
		return
	
	timeCurrent = (Time.get_ticks_usec() / 1000.0) / 1000 - timeBegin
	print(timeCurrent)
	for hitObject in objectContainer.get_children():
		hitObject.move(rect_size.x, timeCurrent)
