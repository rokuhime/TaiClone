class_name AudioQueuer
extends Node2D

@export var audio_players := 5;
var current_audio_player := 0

func _ready():
	for idx in audio_players:
		var new_stream := AudioStreamPlayer2D.new()
		new_stream.bus = "SFX"
		add_child(new_stream)

func play_audio(audio: AudioStream, pos := Vector2.ZERO, vol := 1.0):
	if audio == null:
		Global.push_console("AudioQueuer", "PlayAudio called without valid AudioStream!", 1)
		return
	
	var stream : AudioStreamPlayer2D = get_child(current_audio_player % audio_players)
	
	stream.position = pos
	stream.stream = audio
	stream.volume_db = linear_to_db(vol)
	stream.play()
	current_audio_player += 1
