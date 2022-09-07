class_name SkinManager

# TODO:
# Pippidon
# Playfield (upper half)

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
var bar_right_glow: Texture

## Comment
var bar_right_texture: Texture

## Comment
var big_circle: Texture

## Comment
var don_texture: Texture

## Comment
var f_accurate_judgement: Texture

## Comment
var f_inaccurate_judgement: Texture

## Comment
var hit_circle_overlay: Texture

## The texture of a judgement with an INACCURATE [member HitObject.Score].
var inaccurate_judgement: Texture

## Comment
var kat_texture: Texture

## Comment
var kiai_glow_texture: Texture

## Comment
var lighting_texture: Texture

## Comment
var menu_bg: Texture

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
	kat_color = Color("448dab")
	late_color = Color("5a5aff")
	miss_color = Color("c74b4b")
	roll_color = Color("fc5306")

	## Comment
	var files := []

	## Comment
	var skin_dir := Directory.new()

	if not skin_dir.open(skin_path):
		if skin_dir.list_dir_begin(true):
			skin_dir.list_dir_end()

		else:
			while true:
				## Comment
				var file_name := skin_dir.get_next()

				if file_name:
					if not file_name.ends_with(".import"):
						files.append(file_name.replace("-", "_"))

				else:
					break

	files.sort()
	for key in ["approachcircle", "combobreak", "lighting", "menu_background", "sliderscorepoint", "spinner_approachcircle", "spinner_circle", "spinner_warning", "taiko_bar_left", "taiko_bar_right", "taiko_bar_right_glow", "taiko_drum_hitclap", "taiko_drum_hitfinish", "taiko_drum_hitnormal", "taiko_drum_hitwhistle", "taiko_drum_inner", "taiko_drum_outer", "taiko_glow", "taiko_hit0", "taiko_hit100", "taiko_hit100k", "taiko_hit300", "taiko_hit300k", "taiko_roll_end", "taiko_roll_middle", "taikohitcircle", "taikohitcircleoverlay"]:
		## Comment
		var cur_files := []

		while true:
			if files.empty():
				break

			## Comment
			var file_name := str(files[0])

			## Comment
			var extension := file_name.trim_prefix(str(key))

			if file_name.begins_with(str(key)) and not (extension[0].is_subsequence_of("gko") or extension.begins_with("_g")):
				cur_files.append(extension)

			elif not cur_files.empty() or file_name > str(key):
				break

			files.remove(0)

		match str(key):
			"approachcircle":
				approach_circle = _get_texture(skin_path, str(key), cur_files, 0, [".png"], false)

			"combobreak":
				combo_break = _get_audio(skin_path, str(key), cur_files, [".wav"])

			"lighting":
				lighting_texture = _get_texture(skin_path, str(key), cur_files, 0)

			"menu_background":
				menu_bg = _get_texture(skin_path, str(key), cur_files, 0, [".png"])

			"sliderscorepoint":
				tick_texture = _get_texture(skin_path, str(key), cur_files, 0, [".png"])

			"spinner_approachcircle":
				spinner_approach = _get_texture(skin_path, str(key), cur_files, 0, [".png"], false)

			"spinner_circle":
				spinner_circle = _get_texture(skin_path, str(key), cur_files, 0, [".png"], false)

			"spinner_warning":
				spinner_warning = _get_texture(skin_path, str(key), cur_files, 0, [".png"])

			"taiko_bar_left":
				bar_left_texture = _get_texture(skin_path, str(key), cur_files, 0, [".png"])

			"taiko_bar_right":
				bar_right_texture = _get_texture(skin_path, str(key), cur_files, 0, [".png"])

			"taiko_bar_right_glow":
				bar_right_glow = _get_texture(skin_path, str(key), cur_files, 0)

			"taiko_drum_hitclap":
				hit_clap = _get_audio(skin_path, str(key), cur_files, [".wav"])

			"taiko_drum_hitfinish":
				hit_finish = _get_audio(skin_path, str(key), cur_files, [".wav"])

			"taiko_drum_hitnormal":
				hit_normal = _get_audio(skin_path, str(key), cur_files, [".wav"])

			"taiko_drum_hitwhistle":
				hit_whistle = _get_audio(skin_path, str(key), cur_files, [".wav"])

			"taiko_drum_inner":
				don_texture = _get_texture(skin_path, str(key), cur_files, 0, [".png"], false)

			"taiko_drum_outer":
				kat_texture = _get_texture(skin_path, str(key), cur_files, 0, [".png"], false)

			"taiko_glow":
				kiai_glow_texture = _get_texture(skin_path, str(key), cur_files, 0, [".png"], false)

			"taiko_hit0":
				miss_judgement = _get_texture(skin_path, str(key), cur_files, 1, [".png"], false)

			"taiko_hit100":
				inaccurate_judgement = _get_texture(skin_path, str(key), cur_files, 1, [".png"], false)

			"taiko_hit100k":
				f_inaccurate_judgement = _get_texture(skin_path, str(key), cur_files, 1, [], false)

			"taiko_hit300":
				accurate_judgement = _get_texture(skin_path, str(key), cur_files, 1, [".png"], false)

			"taiko_hit300k":
				f_accurate_judgement = _get_texture(skin_path, str(key), cur_files, 1, [], false)

			"taiko_roll_end":
				roll_end = _get_texture(skin_path, str(key), cur_files, 0, [".png"])

			"taiko_roll_middle":
				roll_middle = _get_texture(skin_path, str(key), cur_files, 0, [".png"])

			"taikohitcircle":
				big_circle = _get_texture(skin_path, str(key), cur_files, 0, [".png"])

			"taikohitcircleoverlay":
				hit_circle_overlay = _get_texture(skin_path, str(key), cur_files, 1, ["-0.png"])


## Comment
func _get_audio(skin_path: String, key: String, cur_files: Array, default_files := []) -> AudioStream:
	if cur_files.empty():
		skin_path = DEFAULT_SKIN_PATH
		cur_files = default_files

	return AudioLoader.load_file(skin_path.plus_file((key + str(cur_files[0])).replace("_", "-")))


## Comment
func _get_texture(skin_path: String, key: String, cur_files: Array, animatable := 0, default_files := [], crop_transparent := true) -> Texture:
	if cur_files.empty():
		skin_path = DEFAULT_SKIN_PATH
		cur_files = default_files

	## Comment
	var frame_idx := 0

	## Comment
	var new_texture := AnimatedTexture.new()

	for file_name in cur_files:
		if str(file_name).begins_with("_%s" % frame_idx):
			frame_idx += 1
			new_texture.frames = frame_idx

		new_texture.set_frame_texture(new_texture.frames - 1, GlobalTools.texture_from_image(skin_path.plus_file((key + str(file_name)).replace("_", "-")), crop_transparent))

	if not animatable or new_texture.frames == 1:
		return new_texture.get_frame_texture(0)

	return new_texture
