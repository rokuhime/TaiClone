class_name Bars
extends Scene

## Comment
var back_scene: PackedScene

onready var root_viewport := $"/root" as Root
onready var top := $Top as Control
onready var song_info := $Top/V/Top/SongInfo as Label
onready var difficulty_rating := $Top/V/Bottom/DifficultyRating as Label
onready var difficulty_icon := $Top/V/Bottom/DifficultyIcon as TextureRect
onready var chart_info := $Top/V/Bottom/ChartInfo as Label
onready var play_date := $Top/V/Bottom/PlayDate as Label
onready var bottom := $Bottom as Control
onready var back_button := $Bottom/H/Back as Clickable
onready var back_label := $Bottom/H/Back/Label as Label
onready var profile := $Bottom/Profile as Clickable
onready var profile_picture := $Bottom/Profile/Organizer/ProfilePicture as TextureRect
onready var texture_rect := $Bottom/Profile/Organizer/Info/Level/TextureRect as TextureRect


func _ready() -> void:
	#GlobalTools.send_signal(self, "song_properties_changed", root_viewport, "change_text")
	change_text()
	apply_skin()
	back_button.background.texture = root_viewport.box_flat
	back_label.text = "<<<"
	profile.texture = root_viewport.box_white
	profile.background.texture = root_viewport.box_black
	difficulty_icon.modulate = Color("6f6cf4")
	play_date.text = Time.get_datetime_string_from_system().replace("T", ", ")

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


## Applies the [member root_viewport]'s [SkinManager] to this [Node]. This method is seen in all [Node]s in the "Skinnables" group.
func apply_skin() -> void:
	profile_picture.texture = root_viewport.skin.mod_sudden_death
	texture_rect.texture = root_viewport.skin.tick_texture


## Comment
func back_button_pressed() -> void:
	root_viewport.add_blackout(back_scene)


## Comment
func change_text() -> void:
	chart_info.text = root_viewport.chart.chart_info()
	difficulty_rating.text = "?"
	song_info.text = root_viewport.chart.song_info()
