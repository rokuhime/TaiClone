extends Node

onready var songAud = get_node("Song")
export var offset = 1
export var baseVelocity = 1

func getSongPos() -> float:
	var song_position_raw = (
			songAud.get_playback_position() 
			+ AudioServer.get_time_since_last_mix()
			- AudioServer.get_output_latency()
		)
	return song_position_raw
