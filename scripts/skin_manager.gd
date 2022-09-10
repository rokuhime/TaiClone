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

## Comment
#var pippidon_clear: AnimatedTexture

## Comment
#var pippidon_fail: AnimatedTexture

## Comment
var pippidon_idle: AnimatedTexture

## Comment
var pippidon_kiai: AnimatedTexture

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
var f_accurate_results: Texture

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
var bar_right_glow: Texture

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

## Comment
#var welcome_text: Texture

## Comment
#var menu_snow: Texture

## Comment
#var button_left: Texture

## Comment
#var button_middle: Texture

## Comment
#var button_right: Texture

## Comment
#var cursor_texture: Texture

## Comment
#var cursor_middle: Texture

## Comment
#var cursor_smoke: Texture

## Comment
#var cursor_trail: Texture

## Comment
#var cursor_ripple: Texture

## Comment
#var mod_auto: Texture

## Comment
#var mod_cinema: Texture

## Comment
#var mod_double_time: Texture

## Comment
#var mod_easy: Texture

## Comment
#var mod_flashlight: Texture

## Comment
#var mod_half_time: Texture

## Comment
#var mod_hard_rock: Texture

## Comment
#var mod_hidden: Texture

## Comment
#var mod_nightcore: Texture

## Comment
#var mod_no_fail: Texture

## Comment
#var mod_perfect: Texture

## Comment
#var mod_relax: Texture

## Comment
#var mod_score: Texture

## Comment
var mod_sudden_death: Texture

## Comment
#var mod_free: Texture

## Comment
#var mod_touch_device: Texture

## Comment
#var offset_tick: Texture

## Comment
#var play_skip: AnimatedTexture

## Comment
#var play_unranked: Texture

## Comment
#var warning_arrow: Texture

## Comment
#var arrow_pause: Texture

## Comment
#var arrow_warning: Texture

## Comment
#var masking_border: Texture

## Comment
#var multi_skipped: Texture

## Comment
#var section_fail: Texture

## Comment
#var section_pass: Texture

## Comment
#var count_one: Texture

## Comment
#var count_two: Texture

## Comment
#var count_three: Texture

## Comment
#var count_go: Texture

## Comment
#var count_ready: Texture

## Comment
#var input_background: Texture

## Comment
#var input_key: Texture

## Comment
#var pause_overlay: Texture

## Comment
#var fail_background: Texture

## Comment
#var pause_back: Texture

## Comment
#var pause_continue: Texture

## Comment
#var pause_replay: Texture

## Comment
#var pause_retry: Texture

## Comment
#var health_bg: Texture

## Comment
#var health_texture: AnimatedTexture

## Comment
#var health_ki: Texture

## Comment
#var health_danger: Texture

## Comment
#var health_danger_two: Texture

## Comment
#var health_marker: Texture

## Comment
#var score_texture: AnimatedTexture

## Comment
#var score_comma: Texture

## Comment
#var score_dot: Texture

## Comment
#var score_percent: Texture

## Comment
#var ranking_xh: Texture

## Comment
#var ranking_xh_small: Texture

## Comment
#var ranking_x: Texture

## Comment
#var ranking_x_small: Texture

## Comment
#var ranking_sh: Texture

## Comment
#var ranking_sh_small: Texture

## Comment
#var ranking_s: Texture

## Comment
var ranking_s_small: Texture

## Comment
#var ranking_a: Texture

## Comment
#var ranking_a_small: Texture

## Comment
#var ranking_b: Texture

## Comment
#var ranking_b_small: Texture

## Comment
#var ranking_c: Texture

## Comment
#var ranking_c_small: Texture

## Comment
#var ranking_d: Texture

## Comment
#var ranking_d_small: Texture

## Comment
#var ranking_accuracy: Texture

## Comment
#var ranking_graph: Texture

## Comment
#var ranking_combo: Texture

## Comment
#var ranking_panel: Texture

## Comment
#var ranking_perfect: Texture

## Comment
#var ranking_title: Texture

## Comment
#var ranking_replay: Texture

## Comment
#var ranking_retry: Texture

## Comment
#var ranking_winner: Texture

## Comment
#var entry_texture: AnimatedTexture

## Comment
#var entry_comma: Texture

## Comment
#var entry_dot: Texture

## Comment
#var entry_percent: Texture

## Comment
#var entry_x: Texture

## Comment
#var menu_back: AnimatedTexture

## Comment
#var selection_background: Texture

## Comment
#var selection_mode: Texture

## Comment
#var selection_mode_over: Texture

## Comment
#var selection_mods: Texture

## Comment
#var selection_mods_over: Texture

## Comment
#var selection_random: Texture

## Comment
#var selection_random_over: Texture

## Comment
#var selection_options: Texture

## Comment
#var selection_options_over: Texture

## Comment
#var selection_tab: Texture

## Comment
#var star: Texture

## Comment
#var star_two: Texture

## Comment
#var mode_texture: Texture

## Comment
#var mode_med: Texture

## Comment
#var mode_small: Texture


# ZMTT TODO: Sounds skinning
func _init(skin_path: String) -> void:
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
	for key in ["approachcircle", "arrow_pause", "arrow_warning", "button_left", "button_middle", "button_right", "combobreak", "count1", "count2", "count3", "cursor", "cursor_ripple", "cursor_smoke", "cursormiddle", "cursortrail", "fail_background", "go", "inputoverlay_background", "inputoverlay_key", "lighting", "masking_border", "menu_back", "menu_background", "menu_button_background", "menu_snow", "mode_taiko", "mode_taiko_med", "mode_taiko_small", "multi_skipped", "options_offset_tick", "pause_back", "pause_continue", "pause_overlay", "pause_replay", "pause_retry", "pippidonclear", "pippidonfail", "pippidonidle", "pippidonkiai", "play_skip", "play_unranked", "play_warningarrow", "ranking_A", "ranking_A_small", "ranking_B", "ranking_B_small", "ranking_C", "ranking_C_small", "ranking_D", "ranking_D_small", "ranking_S", "ranking_SH", "ranking_SH_small", "ranking_S_small", "ranking_X", "ranking_XH", "ranking_XH_small", "ranking_X_small", "ranking_accuracy", "ranking_graph", "ranking_maxcombo", "ranking_panel", "ranking_perfect", "ranking_replay", "ranking_retry", "ranking_title", "ranking_winner", "ready", "score", "score_comma", "score_dot", "score_percent", "scorebar_bg", "scorebar_colour", "scorebar_ki", "scorebar_kidanger", "scorebar_kidanger2", "scorebar_marker", "scoreentry", "scoreentry_comma", "scoreentry_dot", "scoreentry_percent", "scoreentry_x", "section_fail", "section_pass", "selection_mod_autoplay", "selection_mod_cinema", "selection_mod_doubletime", "selection_mod_easy", "selection_mod_flashlight", "selection_mod_freemodallowed", "selection_mod_halftime", "selection_mod_hardrock", "selection_mod_hidden", "selection_mod_nightcore", "selection_mod_nofail", "selection_mod_perfect", "selection_mod_relax", "selection_mod_scorev2", "selection_mod_suddendeath", "selection_mod_touchdevice", "selection_mode", "selection_mode_over", "selection_mods", "selection_mods_over", "selection_options", "selection_options_over", "selection_random", "selection_random_over", "selection_tab", "sliderscorepoint", "spinner_approachcircle", "spinner_circle", "spinner_warning", "star", "star2", "taiko_bar_left", "taiko_bar_right", "taiko_bar_right_glow", "taiko_drum_inner", "taiko_drum_outer", "taiko_flower_group", "taiko_glow", "taiko_hit0", "taiko_hit100", "taiko_hit100k", "taiko_hit300", "taiko_hit300g", "taiko_hit300k", "taiko_normal_hitclap", "taiko_normal_hitfinish", "taiko_normal_hitnormal", "taiko_normal_hitwhistle", "taiko_roll_end", "taiko_roll_middle", "taiko_slider", "taiko_slider_fail", "taikobigcircle", "taikobigcircleoverlay", "taikohitcircle", "taikohitcircleoverlay", "welcome_text"]:
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

		match str(key):
			# "base_file_name":
			#     audio_variable = _get_audio(skin_path, str(key), cur_files, ["default_skin_file_extension"])
			#     texture_variable = _get_texture(skin_path, str(key), cur_files, ["default_skin_file_extensions"], "-", crop_out_transparent_edges).get_frame_texture(0)
			#     texture_animation = _get_texture(skin_path, str(key), cur_files, ["default_skin_file_extensions"], animation_prefix, crop_out_transparent_edges, maximum_animation_frames)

			"approachcircle":
				approach_circle = _get_texture(skin_path, str(key), cur_files, [".png"], "-", false).get_frame_texture(0)

			#"arrow_pause":
			#	arrow_pause = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"arrow_warning":
			#	arrow_warning = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"button_left":
			#	button_left = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"button_middle":
			#	button_middle = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"button_right":
			#	button_right = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			"combobreak":
				combo_break = _get_audio(skin_path, str(key), cur_files, [".wav"])

			#"count1":
			#	count_one = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"count2":
			#	count_two = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"count3":
			#	count_three = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"cursor":
			#	cursor_texture = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			# ZMTT TODO: Test
			#"cursor_ripple":
			#	cursor_ripple = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"cursor_smoke":
			#	cursor_smoke = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			# ZMTT TODO: Test
			#"cursormiddle":
			#	cursor_middle = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"cursortrail":
			#	cursor_trail = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"fail_background":
			#	fail_background = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"go":
			#	count_go = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"inputoverlay_background":
			#	input_background = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"inputoverlay_key":
			#	input_key = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"lighting":
			#	lighting_texture = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			# ZMTT TODO: Test
			#"masking_border":
			#	masking_border = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"menu_back":
			#	menu_back = _get_texture(skin_path, str(key), cur_files, [], "_")

			"menu_background":
				menu_bg = _get_texture(skin_path, str(key), cur_files, [".png"]).get_frame_texture(0)

			#"menu_button_background":
			#	selection_background = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"menu_snow":
			#	menu_snow = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"mode_taiko":
			#	mode_texture = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"mode_taiko_med":
			#	mode_med = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"mode_taiko_small":
			#	mode_small = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			# ZMTT TODO: Test
			#"multi_skipped":
			#	multi_skipped = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			# ZMTT TODO: Test
			#"options_offset_tick":
			#	offset_tick = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"pause_back":
			#	pause_back = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"pause_continue":
			#	pause_continue = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"pause_overlay":
			#	pause_overlay = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"pause_replay":
			#	pause_replay = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"pause_retry":
			#	pause_retry = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"pippidonclear":
			#	pippidon_clear = _get_texture(skin_path, str(key), cur_files, [], "", false, 7)
			#	# ZMTT TODO: Special Animation

			#"pippidonfail":
			#	pippidon_fail = _get_texture(skin_path, str(key), cur_files, [], "", false)

			"pippidonidle":
				pippidon_idle = _get_texture(skin_path, str(key), cur_files, ["0.png", "1.png"], "", false)
				pippidon_idle.pause = true

			"pippidonkiai":
				pippidon_kiai = _get_texture(skin_path, str(key), cur_files, ["0.png", "1.png"], "", false)
				pippidon_kiai.pause = true

			#"play_skip":
			#	play_skip = _get_texture(skin_path, str(key), cur_files, [], "_")

			#"play_unranked":
			#	play_unranked = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"play_warningarrow":
			#	warning_arrow = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"ranking_A":
			#	ranking_a = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"ranking_A_small":
			#	ranking_a_small = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"ranking_B":
			#	ranking_b = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"ranking_B_small":
			#	ranking_b_small = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"ranking_C":
			#	ranking_c = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"ranking_C_small":
			#	ranking_c_small = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"ranking_D":
			#	ranking_d = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"ranking_D_small":
			#	ranking_d_small = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"ranking_S":
			#	ranking_s = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			"ranking_S_small":
				ranking_s_small = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"ranking_SH":
			#	ranking_sh = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"ranking_SH_small":
			#	ranking_sh_small = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"ranking_X":
			#	ranking_x = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"ranking_X_small":
			#	ranking_x_small = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"ranking_XH":
			#	ranking_xh = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"ranking_XH_small":
			#	ranking_xh_small = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"ranking_accuracy":
			#	ranking_accuracy = _get_texture(skin_path, str(key), cur_files, [], "_").get_frame_texture(0)

			#"ranking_graph":
			#	ranking_graph = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"ranking_maxcombo":
			#	ranking_combo = _get_texture(skin_path, str(key), cur_files, [], "_").get_frame_texture(0)

			#"ranking_panel":
			#	ranking_panel = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"ranking_perfect":
			#	ranking_perfect = _get_texture(skin_path, str(key), cur_files, [], "_").get_frame_texture(0)

			# ZMTT TODO: Test
			#"ranking_replay":
			#	ranking_replay = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			# ZMTT TODO: Test
			#"ranking_retry":
			#	ranking_retry = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"ranking_title":
			#	ranking_title = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"ranking_winner":
			#	ranking_winner = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"ready":
			#	count_ready = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"score":
			#	score_texture = _get_texture(skin_path, str(key), cur_files, [], "_", true, 10)

			#"score_comma":
			#	score_comma = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"score_dot":
			#	score_dot = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"score_percent":
			#	score_percent = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"scorebar_bg":
			#	health_bg = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"scorebar_colour":
			#	health_texture = _get_texture(skin_path, str(key), cur_files, [], "_")

			#"scorebar_ki":
			#	health_ki = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"scorebar_kidanger":
			#	health_danger = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			# ZMTT TODO: Test
			#"scorebar_kidanger2":
			#	health_danger_two = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			# ZMTT TODO: Test
			#"scorebar_marker":
			#	health_marker = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"scoreentry":
			#	entry_texture = _get_texture(skin_path, str(key), cur_files, [], "_", true, 10)

			#"scoreentry_comma":
			#	entry_comma = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"scoreentry_dot":
			#	entry_dot = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"scoreentry_percent":
			#	entry_percent = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"scoreentry_x":
			#	entry_x = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"section_fail":
			#	section_fail = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"section_pass":
			#	section_pass = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"selection_mod_autoplay":
			#	mod_auto = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"selection_mod_cinema":
			#	mod_cinema = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"selection_mod_doubletime":
			#	mod_double_time = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"selection_mod_easy":
			#	mod_easy = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"selection_mod_flashlight":
			#	mod_flashlight = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			# ZMTT TODO: Test
			#"selection_mod_freemodallowed":
			#	mod_free = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"selection_mod_halftime":
			#	mod_half_time = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"selection_mod_hardrock":
			#	mod_hard_rock = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"selection_mod_hidden":
			#	mod_hidden = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"selection_mod_nightcore":
			#	mod_nightcore = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"selection_mod_nofail":
			#	mod_no_fail = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"selection_mod_perfect":
			#	mod_perfect = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"selection_mod_relax":
			#	mod_relax = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"selection_mod_scorev2":
			#	mod_score = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			"selection_mod_suddendeath":
				mod_sudden_death = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"selection_mod_touchdevice":
			#	mod_touch_device = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"selection_mode":
			#	selection_mode = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"selection_mode_over":
			#	selection_mode_over = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"selection_mods":
			#	selection_mods = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"selection_mods_over":
			#	selection_mods_over = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"selection_options":
			#	selection_options = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"selection_options_over":
			#	selection_options_over = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"selection_random":
			#	selection_random = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"selection_random_over":
			#	selection_random_over = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			#"selection_tab":
			#	selection_tab = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			"sliderscorepoint":
				tick_texture = _get_texture(skin_path, str(key), cur_files, [".png"]).get_frame_texture(0)

			"spinner_approachcircle":
				spinner_approach = _get_texture(skin_path, str(key), cur_files, [".png"], "-", false).get_frame_texture(0)

			"spinner_circle":
				spinner_circle = _get_texture(skin_path, str(key), cur_files, [".png"], "-", false).get_frame_texture(0)

			"spinner_warning":
				spinner_warning = _get_texture(skin_path, str(key), cur_files, [".png"]).get_frame_texture(0)

			#"star":
			#	star = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			# ZMTT TODO: Test
			#"star2":
			#	star_two = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

			"taiko_bar_left":
				bar_left_texture = _get_texture(skin_path, str(key), cur_files, [".png"]).get_frame_texture(0)

			"taiko_bar_right":
				bar_right_texture = _get_texture(skin_path, str(key), cur_files, [".png"]).get_frame_texture(0)

			"taiko_bar_right_glow":
				if cur_files.empty():
					bar_right_glow = bar_right_texture

				else:
					bar_right_glow = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)

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
				miss_judgement.oneshot = true

			"taiko_hit100":
				inaccurate_judgement = _get_texture(skin_path, str(key), cur_files, [".png"], "_", false)
				inaccurate_judgement.oneshot = true

			"taiko_hit100k":
				f_inaccurate_judgement = _get_texture(skin_path, str(key), cur_files, [".png"], "_", false)
				f_inaccurate_judgement.oneshot = true

			"taiko_hit300":
				accurate_judgement = _get_texture(skin_path, str(key), cur_files, [".png"], "_", false)
				accurate_judgement.oneshot = true

			"taiko_hit300g":
				if cur_files.empty():
					f_accurate_results = accurate_judgement.get_frame_texture(0)

				else:
					f_accurate_results = _get_texture(skin_path, str(key), cur_files, [], "_", false).get_frame_texture(0)

			"taiko_hit300k":
				f_accurate_judgement = _get_texture(skin_path, str(key), cur_files, [".png"], "_", false)
				f_accurate_judgement.oneshot = true

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
				big_circle_overlay.pause = true

			"taikohitcircle":
				hit_circle = _get_texture(skin_path, str(key), cur_files, [".png"]).get_frame_texture(0)

			"taikohitcircleoverlay":
				hit_circle_overlay = _get_texture(skin_path, str(key), cur_files, ["_0.png"], "_", true, 2)
				hit_circle_overlay.pause = true

			#"welcome_text":
			#	welcome_text = _get_texture(skin_path, str(key), cur_files).get_frame_texture(0)


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

	new_texture.fps = 60
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
