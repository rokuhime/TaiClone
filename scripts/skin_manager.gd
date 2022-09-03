class_name SkinManager

## Comment
const DEFAULT_SKIN_PATH := "res://skins/test_skin"

## Comment
var combo_break: AudioStream

## Comment
var hit_clap: AudioStream

## Comment
var hit_finish: AudioStream

## Comment
var hit_normal: AudioStream

## Comment
var hit_whistle: AudioStream

## The color of hit error markers with an ACCURATE [member HitObject.Score].
var accurate_color: Color

## The color of [BarLine]s.
var barline_color: Color

## The color of don [Note]s.
var don_color: Color

## The color of an early timing indicator or container.
var early_color: Color

## The color of hit error markers with an INACCURATE [member HitObject.Score].
var inaccurate_color: Color

## The color of kat [Note]s.
var kat_color: Color

## The color of a late timing indicator or container.
var late_color: Color

## The color of hit error markers with a MISS [member HitObject.Score].
var miss_color: Color

## The color of [Roll]s.
var roll_color: Color

## The texture of a judgement with an ACCURATE [member HitObject.Score].
var accurate_judgement: Texture

## Comment
var approach_circle: Texture

## Comment
var bar_left_texture: Texture

## Comment
var bar_right_texture: Texture

## Comment
var big_circle: Texture

## Comment
var don_texture: Texture

## Comment
var hit_circle_overlay: Texture

## The texture of a judgement with an INACCURATE [member HitObject.Score].
var inaccurate_judgement: Texture

## Comment
var kat_texture: Texture

## The texture of a judgement with a MISS [member HitObject.Score].
var miss_judgement: Texture

## Comment
var roll_end: Texture

## Comment
var roll_middle: Texture

## Comment
var spinner_approach: Texture

## Comment
var spinner_circle: Texture

## Comment
var spinner_warning: Texture

## Comment
var tick_texture: Texture


func _init(skin_path := DEFAULT_SKIN_PATH) -> void:
	accurate_color = Color("52a6ff")
	barline_color = Color.white
	don_color = Color("eb452c")
	early_color = Color("ff5a5a")
	inaccurate_color = Color("79da5e")
	kat_color = Color("438eac")
	late_color = Color("5a5aff")
	miss_color = Color("c74b4b")
	roll_color = Color("fcb806")
	_default_skin()
	if skin_path == DEFAULT_SKIN_PATH:
		return

	## Comment
	var skin_dir := Directory.new()

	if skin_dir.open(skin_path):
		return

	if skin_dir.list_dir_begin(true):
		skin_dir.list_dir_end()
		return

	while true:
		## Comment
		var file_name := skin_dir.get_next()

		## Comment
		var file_path := skin_path.plus_file(file_name)

		match file_name.get_basename():
			"":
				return

			"approachcircle":
				approach_circle = ChartLoader.texture_from_image(file_path, false)

			"combobreak":
				combo_break = ChartLoader.load_audio_file(file_path)

			"sliderscorepoint":
				tick_texture = ChartLoader.texture_from_image(file_path)

			"spinner-approachcircle":
				spinner_approach = ChartLoader.texture_from_image(file_path)

			"spinner-circle":
				approach_circle = ChartLoader.texture_from_image(file_path, false)

			"spinner-warning":
				spinner_warning = ChartLoader.texture_from_image(file_path)

			"taiko-bar-left":
				bar_left_texture = ChartLoader.texture_from_image(file_path)

			"taiko-bar-right":
				bar_right_texture = ChartLoader.texture_from_image(file_path)

			"taiko-drum-hitclap":
				hit_clap = ChartLoader.load_audio_file(file_path)

			"taiko-drum-hitfinish":
				hit_finish = ChartLoader.load_audio_file(file_path)

			"taiko-drum-hitnormal":
				hit_normal = ChartLoader.load_audio_file(file_path)

			"taiko-drum-hitwhistle":
				hit_whistle = ChartLoader.load_audio_file(file_path)

			"taiko-drum-inner":
				don_texture = ChartLoader.texture_from_image(file_path, false)

			"taiko-drum-outer":
				kat_texture = ChartLoader.texture_from_image(file_path, false)

			"taiko-hit0":
				miss_judgement = ChartLoader.texture_from_image(file_path, false)

			"taiko-hit100":
				inaccurate_judgement = ChartLoader.texture_from_image(file_path, false)

			"taiko-hit300":
				accurate_judgement = ChartLoader.texture_from_image(file_path, false)

			"taiko-roll-end":
				roll_end = ChartLoader.texture_from_image(file_path)

			"taiko-roll-middle":
				roll_middle = ChartLoader.texture_from_image(file_path)

			"taikobigcircle":
				big_circle = ChartLoader.texture_from_image(file_path)

			"taikohitcircleoverlay-0":
				hit_circle_overlay = ChartLoader.texture_from_image(file_path)


## Comment
func _default_skin() -> void:
	## Comment
	var skin_path := DEFAULT_SKIN_PATH

	combo_break = load(skin_path.plus_file("combobreak.wav")) as AudioStream
	hit_clap = load(skin_path.plus_file("taiko-drum-hitclap.wav")) as AudioStream
	hit_finish = load(skin_path.plus_file("taiko-drum-hitfinish.wav")) as AudioStream
	hit_normal = load(skin_path.plus_file("taiko-drum-hitnormal.wav")) as AudioStream
	hit_whistle = load(skin_path.plus_file("taiko-drum-hitwhistle.wav")) as AudioStream
	accurate_judgement = ChartLoader.texture_from_image(skin_path.plus_file("taiko-hit300.png"), false)
	approach_circle = ChartLoader.texture_from_image(skin_path.plus_file("approachcircle.png"), false)
	bar_left_texture = ChartLoader.texture_from_image(skin_path.plus_file("taiko-bar-left.png"))
	bar_right_texture = ChartLoader.texture_from_image(skin_path.plus_file("taiko-bar-right.png"))
	big_circle = ChartLoader.texture_from_image(skin_path.plus_file("taikobigcircle.png"))
	don_texture = ChartLoader.texture_from_image(skin_path.plus_file("taiko-drum-inner.png"), false)
	hit_circle_overlay = ChartLoader.texture_from_image(skin_path.plus_file("taikohitcircleoverlay-0.png"))
	inaccurate_judgement = ChartLoader.texture_from_image(skin_path.plus_file("taiko-hit100.png"), false)
	kat_texture = ChartLoader.texture_from_image(skin_path.plus_file("taiko-drum-outer.png"), false)
	miss_judgement = ChartLoader.texture_from_image(skin_path.plus_file("taiko-hit0.png"), false)
	roll_end = ChartLoader.texture_from_image(skin_path.plus_file("taiko-roll-end.png"))
	roll_middle = ChartLoader.texture_from_image(skin_path.plus_file("taiko-roll-middle.png"))
	spinner_approach = ChartLoader.texture_from_image(skin_path.plus_file("spinner-approachcircle.png"))
	spinner_circle = ChartLoader.texture_from_image(skin_path.plus_file("spinner-circle.png"), false)
	spinner_warning = ChartLoader.texture_from_image(skin_path.plus_file("spinner-warning.png"))
	tick_texture = ChartLoader.texture_from_image(skin_path.plus_file("sliderscorepoint.png"))
