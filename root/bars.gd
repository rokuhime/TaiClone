extends Scene

onready var root_viewport := $"/root" as Root
onready var top := $Top
onready var song_info := $Top/V/Top/SongInfo as Label
onready var chart_info := $Top/V/Bottom/ChartInfo as Label
onready var difficulty_rating := $Top/V/Bottom/DifficultyRating as Label
onready var difficulty_icon := $Top/V/Bottom/DifficultyIcon as TextureRect
onready var play_date := $Top/V/Bottom/PlayDate as Label
onready var bottom := $Bottom


func _ready() -> void:
	# temporary replacements
	difficulty_rating.text = "8.01"
	chart_info.text = "Hell Oni - Genjuro"
	song_info.text = "Sanae-San - RD-Sounds feat. Meramipop"
	difficulty_icon.modulate = 	Color("6f6cf4")

	#charter_name.text = root_viewport.charter
	#difficulty_name_label.text = root_viewport.difficulty_name
	#song_name.text = "%s - %s" % [root_viewport.title, root_viewport.artist]

	# i know its a little dumber but it looks nicer :^(
	play_date.text = Time.get_date_string_from_system(false) + ", " + Time.get_time_string_from_system(false)

	## Comment
	var position_tween := root_viewport.new_tween(SceneTreeTween.new()).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT).set_parallel()

	## Comment
	var _top_tween := position_tween.tween_property(top, "rect_position:y", 0.0, 1).from(-100.0)

	## Comment
	var _bottom_tween := position_tween.tween_property(bottom, "rect_position:y", 980.0, 1).from(1080.0)

## Comment
func back_button_pressed() -> void:
	root_viewport.add_blackout(root_viewport.main_menu)
