extends TextureRect

const KEYS := ["LeftKat", "LeftDon", "RightDon", "RightKat"]

var _l_don_tween := SceneTreeTween.new()
var _l_kat_tween := SceneTreeTween.new()
var _r_don_tween := SceneTreeTween.new()
var _r_kat_tween := SceneTreeTween.new()

onready var l_don_obj := $LeftDon as TextureRect
onready var l_kat_obj := $LeftKat as TextureRect
onready var r_don_obj := $RightDon as TextureRect
onready var r_kat_obj := $RightKat as TextureRect

onready var l_don_aud := $LeftDonAudio as AudioStreamPlayer
onready var l_kat_aud := $LeftKatAudio as AudioStreamPlayer
onready var r_don_aud := $RightDonAudio as AudioStreamPlayer
onready var r_kat_aud := $RightKatAudio as AudioStreamPlayer

func _unhandled_input(event: InputEvent) -> void:
	var inputs = []

	for key in KEYS:
		if event.is_action_pressed(str(key)):
			inputs.append(str(key))

			var drum_obj: Node

			## Comment
			var scene_tween: SceneTreeTween

			match key:
				"LeftDon":
					drum_obj = l_don_obj
					scene_tween = _l_don_tween
				
				"LeftKat":
					drum_obj = l_kat_obj
					scene_tween = _l_kat_tween
					
				"RightDon":
					drum_obj = r_don_obj
					scene_tween = _r_don_tween
					
				"RightKat":
					drum_obj = r_kat_obj
					scene_tween = _r_kat_tween
					
				_:
					push_warning("Unknown keypress animation.")
					
			play_audio(key)

			scene_tween = create_tween().set_ease(Tween.EASE_OUT)

			## Comment
			var _tween := scene_tween.tween_property(drum_obj, "modulate:a", 0.0, 0.2).from(1.0)	

func play_audio(key: String) -> void:
	match key:
		"LeftDon":
			l_don_aud.play()

		"LeftKat":
			l_kat_aud.play()

		"RightDon":
			r_don_aud.play()

		"RightKat":
			r_kat_aud.play()
