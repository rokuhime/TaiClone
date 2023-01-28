extends Node

var playing := false

onready var song := $Song as AudioStreamPlayer

var timeCurrent := 0.0
var timeBegin := 0.0

func changeChartPlayback():
	if not playing:
		song.play()
		timeBegin += Time.get_ticks_usec() / 1000000.0 + AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
			
	playing = not playing
