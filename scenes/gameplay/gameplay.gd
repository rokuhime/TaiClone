extends Node

var playing := false

onready var song := $Song as AudioStreamPlayer
onready var track := $Track as Track

var timeCurrent := 0.0
var timeBegin := 0.0

func changeChartPlayback() -> void:
	if not playing:
		song.play()
		timeBegin += Time.get_ticks_usec() / 1000000.0 + AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
			
	playing = not playing

func _process(_delta) -> void:
	if not playing:
		return	

	timeCurrent = (Time.get_ticks_usec() / 1000.0) / 1000 - timeBegin
	track.moveObjects(timeCurrent)
