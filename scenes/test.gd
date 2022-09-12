extends Scene

onready var audio_stream_player := $AudioStreamPlayer as AudioStreamPlayer


func _ready() -> void:
	audio_stream_player.play(32.092)
