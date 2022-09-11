extends Scene

onready var root_viewport := $"/root" as Root
onready var top := $Top as Control
onready var song_info := $Top/V/Top/SongInfo as Label
onready var difficulty_rating := $Top/V/Bottom/DifficultyRating as Label
onready var difficulty_icon := $Top/V/Bottom/DifficultyIcon as TextureRect
onready var chart_info := $Top/V/Bottom/ChartInfo as Label
onready var play_date := $Top/V/Bottom/PlayDate as Label
onready var bottom := $Bottom as Control
onready var profile_picture := $Bottom/Profile/Organizer/ProfilePicture as TextureRect
onready var texture_rect := $Bottom/Profile/Organizer/Info/Level/TextureRect as TextureRect


func _ready() -> void:
	add_to_group("Skinnables")
	apply_skin()
	chart_info.text = "%s - %s" % [root_viewport.difficulty_name, root_viewport.charter]
	difficulty_icon.modulate = Color("6f6cf4")
	difficulty_rating.text = "8.01"
	play_date.text = Time.get_datetime_string_from_system().replace("T", ", ")
	song_info.text = "%s - %s" % [root_viewport.artist, root_viewport.title]

	## Comment
	var position_tween := root_viewport.new_tween(SceneTreeTween.new()).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT).set_parallel()

	## Comment
	var _bottom_bottom_tween := position_tween.tween_property(bottom, "margin_bottom", 0.0, 1)

	## Comment
	var _bottom_top_tween := position_tween.tween_property(bottom, "margin_top", -bottom.rect_size.y, 1)

	## Comment
	var _top_bottom_tween := position_tween.tween_property(top, "margin_bottom", top.rect_size.y, 1)

	## Comment
	var _top_top_tween := position_tween.tween_property(top, "margin_top", 0.0, 1)


## Comment
func apply_skin() -> void:
	profile_picture.texture = root_viewport.skin.mod_sudden_death
	texture_rect.texture = root_viewport.skin.tick_texture


## Comment
func back_button_pressed() -> void:
	root_viewport.add_blackout(root_viewport.main_menu)
