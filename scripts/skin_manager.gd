class_name SkinManager

# TODO:
# Interface skinning
# Sounds skinning

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

## Comment
#var pippidon_clear: AnimatedTexture

## Comment
#var pippidon_fail: AnimatedTexture

## Comment
#var pippidon_idle: AnimatedTexture

## Comment
#var pippidon_kiai: AnimatedTexture

## The texture of a judgement with a MISS [member HitObject.Score].
var miss_judgement: AnimatedTexture

## The texture of a judgement with an INACCURATE [member HitObject.Score].
var inaccurate_judgement: AnimatedTexture

## Comment
var f_inaccurate_judgement: AnimatedTexture

## The texture of a judgement with an ACCURATE [member HitObject.Score].
var accurate_judgement: AnimatedTexture

## Comment
var f_accurate_judgement: AnimatedTexture

## Comment
#var f_accurate_results: Texture

## Comment
var big_circle: Texture

## Comment
var big_circle_overlay: AnimatedTexture

## Comment
var hit_circle: Texture

## Comment
var hit_circle_overlay: AnimatedTexture

## Comment
var approach_circle: Texture

## Comment
var kiai_glow_texture: Texture

## Comment
#var lighting_texture: Texture

## Comment
#var slider_pass: Texture

## Comment
#var slider_fail: Texture

## Comment
#var flower_group: AnimatedTexture

## Comment
var bar_left_texture: Texture

## Comment
var don_texture: Texture

## Comment
var kat_texture: Texture

## Comment
var bar_right_texture: Texture

## Comment
#var bar_right_glow: Texture

## Comment
var roll_middle: Texture

## Comment
var roll_end: Texture

## Comment
var tick_texture: Texture

## Comment
var spinner_warning: Texture

## Comment
var spinner_circle: Texture

## Comment
var spinner_approach: Texture

## Comment
var menu_bg: Texture


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
	# Both of these lists MUST be in alphabetical order to function
	for key in ["approachcircle", "combobreak", "lighting", "menu_background", "pippidonclear", "pippidonfail", "pippidonidle", "pippidonkiai", "sliderscorepoint", "spinner_approachcircle", "spinner_circle", "spinner_warning", "taiko_bar_left", "taiko_bar_right", "taiko_bar_right_glow", "taiko_drum_inner", "taiko_drum_outer", "taiko_flower_group", "taiko_glow", "taiko_hit0", "taiko_hit100", "taiko_hit100k", "taiko_hit300", "taiko_hit300g", "taiko_hit300k", "taiko_normal_hitclap", "taiko_normal_hitfinish", "taiko_normal_hitnormal", "taiko_normal_hitwhistle", "taiko_roll_end", "taiko_roll_middle", "taiko_slider", "taiko_slider_fail", "taikobigcircle", "taikobigcircleoverlay", "taikohitcircle", "taikohitcircleoverlay"]:
		## Comment
		var cur_files := []

		while true:
			if files.empty():
				break

			## Comment
			var file_name := str(files[0]).trim_prefix(str(key))

			## Comment
			var extension := file_name.get_basename().trim_suffix("@2x").replace("_", "-")

			if extension.is_valid_integer() or not extension:
				cur_files.append(file_name)

			elif not cur_files.empty() or file_name > str(key):
				break

			files.remove(0)

		print(str(key), " | ", cur_files)
		match str(key):
			# "base_file_name":
			#     audio_variable = _get_audio(skin_path, str(key), cur_files, ["default_skin_file_extension"])
			#     texture_variable = _get_texture(skin_path, str(key), cur_files, ["default_skin_file_extensions"], "-", crop_out_transparent_edges).get_frame_texture(0)
			#     texture_animation = _get_texture(skin_path, str(key), cur_files, ["default_skin_file_extensions"], animation_prefix, crop_out_transparent_edges, maximum_animation_frames)

			"approachcircle":
				approach_circle = _get_texture(skin_path, str(key), cur_files, [".png"], "-", false).get_frame_texture(0)

			"combobreak":
				combo_break = _get_audio(skin_path, str(key), cur_files, [".wav"])

			#"lighting":
			#	lighting_texture = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			"menu_background":
				menu_bg = _get_texture(skin_path, str(key), cur_files, [".png"]).get_frame_texture(0)

			#"pippidonclear":
			#	pippidon_clear = _get_texture(skin_path, str(key), cur_files, [], "", true, 7)
			#	# ZMTT TODO: Special Animation

			#"pippidonfail":
			#	pippidon_fail = _get_texture(skin_path, str(key), cur_files, [], "")

			#"pippidonidle":
			#	pippidon_idle = _get_texture(skin_path, str(key), cur_files, [], "")

			#"pippidonkiai":
			#	pippidon_kiai = _get_texture(skin_path, str(key), cur_files, [], "")

			"sliderscorepoint":
				tick_texture = _get_texture(skin_path, str(key), cur_files, [".png"]).get_frame_texture(0)

			"spinner_approachcircle":
				spinner_approach = _get_texture(skin_path, str(key), cur_files, [".png"], "-", false).get_frame_texture(0)

			"spinner_circle":
				spinner_circle = _get_texture(skin_path, str(key), cur_files, [".png"], "-", false).get_frame_texture(0)

			"spinner_warning":
				spinner_warning = _get_texture(skin_path, str(key), cur_files, [".png"]).get_frame_texture(0)

			"taiko_bar_left":
				bar_left_texture = _get_texture(skin_path, str(key), cur_files, [".png"]).get_frame_texture(0)

			"taiko_bar_right":
				bar_right_texture = _get_texture(skin_path, str(key), cur_files, [".png"]).get_frame_texture(0)

			#"taiko_bar_right_glow":
			#	bar_right_glow = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			"taiko_drum_inner":
				don_texture = _get_texture(skin_path, str(key), cur_files, [".png"], "-", false).get_frame_texture(0)

			"taiko_drum_outer":
				kat_texture = _get_texture(skin_path, str(key), cur_files, [".png"], "-", false).get_frame_texture(0)

			#"taiko_flower_group":
			#	flower_group = _get_texture(skin_path, str(key), cur_files, [], "_")

			"taiko_glow":
				kiai_glow_texture = _get_texture(skin_path, str(key), cur_files, [".png"], "-", false).get_frame_texture(0)

			"taiko_hit0":
				miss_judgement = _get_texture(skin_path, str(key), cur_files, [".png"], "_", false)

			"taiko_hit100":
				inaccurate_judgement = _get_texture(skin_path, str(key), cur_files, [".png"], "_", false)

			"taiko_hit100k":
				f_inaccurate_judgement = _get_texture(skin_path, str(key), cur_files, [".png"], "_", false)

			"taiko_hit300":
				accurate_judgement = _get_texture(skin_path, str(key), cur_files, [".png"], "_", false)

			#"taiko_hit300g":
			#	f_accurate_results = _get_texture(skin_path, str(key), cur_files, [".png"], "_", false).get_frame_texture(0)

			"taiko_hit300k":
				f_accurate_judgement = _get_texture(skin_path, str(key), cur_files, [".png"], "_", false)

			"taiko_normal_hitclap":
				hit_clap = _get_audio(skin_path, str(key), cur_files, [".wav"])

			"taiko_normal_hitfinish":
				hit_finish = _get_audio(skin_path, str(key), cur_files, [".wav"])

			"taiko_normal_hitnormal":
				hit_normal = _get_audio(skin_path, str(key), cur_files, [".wav"])

			"taiko_normal_hitwhistle":
				hit_whistle = _get_audio(skin_path, str(key), cur_files, [".wav"])

			"taiko_roll_end":
				roll_end = _get_texture(skin_path, str(key), cur_files, [".png"]).get_frame_texture(0)

			"taiko_roll_middle":
				roll_middle = _get_texture(skin_path, str(key), cur_files, [".png"]).get_frame_texture(0)

			#"taiko_slider":
			#	slider_pass = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"taiko_slider_fail":
			#	slider_fail = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			"taikobigcircle":
				big_circle = _get_texture(skin_path, str(key), cur_files, [".png"]).get_frame_texture(0)

			"taikobigcircleoverlay":
				big_circle_overlay = _get_texture(skin_path, str(key), cur_files, ["_0.png"], "_", true, 2)

			"taikohitcircle":
				hit_circle = _get_texture(skin_path, str(key), cur_files, [".png"]).get_frame_texture(0)

			"taikohitcircleoverlay":
				hit_circle_overlay = _get_texture(skin_path, str(key), cur_files, ["_0.png"], "_", true, 2)


## Comment
func _get_audio(skin_path: String, key: String, cur_files: Array, default_files := []) -> AudioStream:
	if cur_files.empty():
		skin_path = DEFAULT_SKIN_PATH
		cur_files = default_files

	return AudioLoader.load_file(skin_path.plus_file((key + str(cur_files[0])).replace("_", "-")))


## Comment
func _get_texture(skin_path: String, key: String, cur_files: Array, default_files := [], animation_prefix := "-", crop_transparent := true, max_frames := AnimatedTexture.MAX_FRAMES) -> AnimatedTexture:
	if cur_files.empty():
		skin_path = DEFAULT_SKIN_PATH
		cur_files = default_files

	## Comment
	var frame_idx := 0

	## Comment
	var new_texture := AnimatedTexture.new()

	for file_name in cur_files:
		## Comment
		var extension := str(file_name)

		if animation_prefix == "-":
			extension = extension.trim_prefix("_")
			max_frames = 1
			animation_prefix = ""

		if extension.begins_with(animation_prefix + str(frame_idx)):
			frame_idx += 1

		if frame_idx <= max_frames:
			new_texture.frames = int(max(1, frame_idx))
			new_texture.set_frame_texture(new_texture.frames - 1, GlobalTools.texture_from_image(skin_path.plus_file((key + extension).replace("_", "-")), crop_transparent))

	return new_texture
