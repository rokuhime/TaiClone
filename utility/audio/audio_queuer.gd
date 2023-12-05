class_name AudioQueuer
extends Node2D

@export var audio_players := 5;
var current_audio_player := 0

func _ready():
	for idx in audio_players:
		var new_stream := AudioStreamPlayer2D.new()
		new_stream.bus = "SFX"
		add_child(new_stream)

func play_audio(audio: AudioStream, position := Vector2.ZERO):
	if audio == null:
		print("AudioQueuer: PlayAudio called without valid AudioStream!")
		return
	
	var stream : AudioStreamPlayer2D = get_child(current_audio_player % audio_players)
	
	stream.position = position
	stream.stream = audio
	stream.play()
	current_audio_player += 1
