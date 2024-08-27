class_name SkinManager
# absolute blabber you can ignore this
# in root, we have a player class with their skin
# upon entering gameplay, give that player variable and apply the skin to each aspect of it (ui manager, hitobjs, etc)
# player variables can be edited through the preference menu (separate from settings menu)
# settings is for changing how the program runs, preferences is for personalization

# maybe make this like zachman's implementation? like a get_colour("name") function

var info := ["Default Skin", "rokuhime", "v1.0"]
var file_path: String

# contains all elements of a skin; check its valid with resource_exists() before retrieving!
var resources := {
	"texture": {
		# hit objects
		"note": null,									# middle/inside of a note, tinted to be don/kat colour
		"note_overlay": null,							# overlay of a note
		
		"roll_middle": null,							# center of a roll, stretched to the length of the roll. tinted to roll colour
		"roll_end": null,								# visual indicator of a roll's end. tinted to roll colour
		"roll_tick": null,								# hittable element of a roll
		
		"spinner_warn": null,							# gameplay track element of a spinner
		"spinner_inside": null,							# spinning center of a spinner 
		"spinner_outside": null,						# approach circle of a spinner
		
		# playfield
		"track": null,									# backing for the chart's gameplay
		"drum_indicator": null,							# circle to the left of the track, 
		"drum_indicator_don": null,						# visual on top of drum_indicator, for dons
		"drum_indicator_kat": null,						# visual on top of drum_indicator, for kats
		
		# judgements
		"judgement_accurate": null,						# picture that appears over the HitPoint for accurate hits
		"judgement_accurate_f": null,					# picture that appears over the HitPoint for accurate finisher hits
		"judgement_inaccurate": null,					# picture that appears over the HitPoint for inaccurate hits
		"judgement_inaccurate_f": null,					# picture that appears over the HitPoint for inaccurate finisher hits
		"judgement_miss": null,							# picture that appears over the HitPoint for misses
		
		# mascot
		# WILL BE DEPRECATED FOR MASCOT CREATION!
		"mascot_idle": [],								# default mascot/pippidon animation 
		"mascot_kiai": [],								# kiai mascot/pippidon animation
		"mascot_fail": [],								# miss mascot/pippidon animation
		"mascot_toast": [],								# plays when achieving a combo milestone
	},
	
	"audio": {
		"don": null,									# plays when hitting a don key
		"don_f": null,									# plays when hitting a finisher don note
		"kat": null,									# plays when hitting a kat key
		"kat_f": null,									# plays when hitting a finisher kat note
		
		"combo_break": null,							# plays when you miss while having 10 or more combo
	},
	
	"colour": {
		"don": Color("EB452B"),							# colour of don notes
		"kat": Color("438EAD"),							# colour of kat notes
		"roll": Color("FCB806"),						# colour of a roll's head (base), middle, and end
		
		"late": Color("ff8a8a"),						# used in inacc indicator + results late count
		"early": Color("8aa7ff"),						# used in inacc indicator + results early count
		
		"song_progress_back": Color("333333"),			# backing for song_progress
		"song_progress_front": Color("ffffff"),			# elapsed time for song_progress
		"song_progress_skippable": Color("8bff85"),		# remaining time to first note for song_progress
	}
}

# list of texture elements that won't have their transparency cropped
const dont_crop_list := [
	"drum_indicator",
	"drum_indicator_don",
	"drum_indicator_kat",
	
	"spinner_inside",
	"roll_middle",
	
	"judgement_accurate",
	"judgement_accurate_f",
	"judgement_inaccurate",
	"judgement_inaccurate_f",
	"judgement_miss",
]

# translator from osu! texture filenames to taiclone texture names
const valid_osu_textures := {
	"taikohitcircle": "note", 
	"taikohitcircleoverlay": "note_overlay", 
	"taiko-roll-middle": "roll_middle",
	"taiko-roll-end": "roll_end",
	"sliderscorepoint": "roll_tick",
	"spinner-warning": "spinner_warn", 
	"spinner-circle": "spinner_inside", 
	"spinner-approachcircle": "spinner_outside",
	
	"taiko-bar-right": "track",
	"taiko-bar-left": "drum_indicator",
	"taiko-drum-inner": "drum_indicator_don",
	"taiko-drum-outer": "drum_indicator_kat",
	
	"taiko-hit300": "judgement_accurate",
	"taiko-hit300g": "judgement_accurate_f",
	"taiko-hit100": "judgement_inaccurate",
	"taiko-hit100g": "judgement_inaccurate_f",
	"taiko-hit0": "judgement_miss",
	
	"pippidonidle": "mascot_idle",
	"pippidonkiai": "mascot_kiai",
	"pippidonfail": "mascot_fail",
	"pippidonclear": "mascot_toast",
}

# translator for osu! audio files to taiclone audio names
const valid_osu_audio := {
	"taiko-normal-hitnormal": "don",
	"taiko-normal-hitfinish": "don_f",
	"taiko-normal-hitclap": "kat",
	"taiko-normal-hitwhistle": "kat_f",
	
	"combobreak": "combo_break",
}

func _init(new_file_path = null):
	if new_file_path:
		if not DirAccess.dir_exists_absolute(new_file_path):
			Global.push_console("SkinManager", "Invalid skin directory: %s" % new_file_path)
			return 
		if new_file_path.is_empty():
			return
		
		file_path = new_file_path
		info = get_info(file_path)
		
		var all_textures = get_all_textures(file_path)
		resources["texture"] = all_textures
		var all_audio = get_all_audio(file_path)
		resources["audio"] = all_audio
		
		var pippidon_textures = get_pippidon_textures(file_path)
		var tc_mascot_sprite_names = ["mascot_idle", "mascot_kiai", "mascot_fail", "mascot_toast"]
		for key in tc_mascot_sprite_names:
			resources["texture"][key] = pippidon_textures[key]

# ensures null skin elements dont cause issues
# resource_location : resourcetype/resourcename (eg audio/don)
func resource_exists(resource_location: String):
	# assume no skins been loaded if theres no file path
	if not file_path:
		return false
	
	var resource_info = resource_location.split("/")
	
	if resource_info.size() == 2:
		if resources[resource_info[0]].keys().has(resource_info[1]):
			if resources[resource_info[0]][resource_info[1]]:
				return true
	return false

# checks skin.ini for name/artist/version
static func get_info(directory: String) -> Array:
	var file_names := DirAccess.get_files_at(directory)
	# default the skin name to the skin folder's name
	var skin_info := [directory.trim_prefix(directory.get_base_dir() + "/"), "Unknown Author", "v0.0"]
	
	if not file_names.has("skin.ini"):
		return skin_info
	
	var file := FileAccess.open(directory.path_join("skin.ini"), FileAccess.READ)
	if !file:
		Global.push_console("ChartLoader", "Bad directory provided for skin: %s" % directory, 2)
		return skin_info
	
	var line := ""
	var found_skin_info := [null, null, null]
	while file.get_position() < file.get_length():
		# if we find all the entries, break out
		if not found_skin_info.find(null) + 1:
			break
		
		line = file.get_line().strip_edges()
		if line.begins_with("Name:"):
			found_skin_info[0] = line.trim_prefix("Name:").strip_edges()
		elif line.begins_with("Author:"):
			found_skin_info[1] = line.trim_prefix("Author:").strip_edges()
		elif line.begins_with("Version:"):
			found_skin_info[2] = line.trim_prefix("Version:").strip_edges()
	
	for i in skin_info.size():
		if found_skin_info[i]:
			skin_info[i] = found_skin_info[i]
	return skin_info

# TODO: animated textures
static func get_all_textures(directory: String) -> Dictionary:
	var file_names := DirAccess.get_files_at(directory)
	var resource_filenames := {}
	
	for file in file_names:
		if not file.ends_with(".png"):
			continue
		
		# check for files named [texture_name].png, [texture_name]@2x.png, or [texture_name]-0.png
		var basename: String = file.get_basename()
		var suffix := ""
			
		if ["0","1","2","3","4","5","6","7","8","9"].has(basename[basename.length() - 1]):
			suffix += basename.substr(basename.find("-"), basename.length() - 1)
			basename = basename.substr(0,basename.find("-"))
			
		if basename.find("@2x") + 1: 
			suffix += "@2x"
			basename = basename.replace("@2x", "")
		
		if valid_osu_textures.has(basename):
			if resource_filenames.keys().has(basename):
				if not suffix.find("@2x") + 1 and resource_filenames[basename].find("@2x") + 1:
					continue
				# if we already have the first animation in the series
				if suffix.find("-") - 1 and resource_filenames[basename].find("-0") - 1: 
					continue
			resource_filenames[valid_osu_textures[basename]] = file
	
	var texture_resources := {}
	for resource in resource_filenames:
		var new_texture: ImageTexture
		new_texture = ImageLoader.load_image(directory.path_join(resource_filenames[resource]), not dont_crop_list.has(resource))
		texture_resources[resource] = new_texture
	
	return texture_resources

static func get_pippidon_textures(directory: String) -> Dictionary:
	var osu_mascot_sprite_names = ["pippidonidle", "pippidonkiai", "pippidonfail", "pippidonclear"]
	var mascot_textures = {
		"mascot_idle": [],
		"mascot_kiai": [],
		"mascot_fail": [],
		"mascot_toast": [],
	}
	
	var file_names := DirAccess.get_files_at(directory)
	
	for file in file_names:
		if not file.begins_with("pippidon"):
			continue
		file = file.trim_suffix(".png")
		
		var frame = ""
		for i in range(file.length() - 1, -1, -1):
			if ["0","1","2","3","4","5","6","7","8","9"].has(file[i]):
				frame = file[i] + frame
		file = file.replace(frame, "")
		frame = int(frame)
		
		if not valid_osu_textures.keys().has(file):
			continue
		
		# make ImageTexture with the found texture and return it
		var new_texture: ImageTexture
		new_texture = ImageLoader.load_image(directory.path_join(file + str(frame) + ".png"), false)
		mascot_textures[valid_osu_textures[file]].append(new_texture)
	
	return mascot_textures

static func get_all_audio(directory: String) -> Dictionary:
	var file_names := DirAccess.get_files_at(directory)
	var resource_filenames := {}
	
	for file in file_names:
		if not file.ends_with(".wav") and not file.ends_with(".mp3") and not file.ends_with(".ogg"):
			continue
		
		if valid_osu_audio.has(file.get_basename()):
			resource_filenames[valid_osu_audio[file.get_basename()]] = file
	
	var audio_resources := {}
	for resource in resource_filenames:
		var new_audio: AudioStream
		new_audio = AudioLoader.load_file(directory.path_join(resource_filenames[resource]))
		audio_resources[resource] = new_audio
	
	return audio_resources
