class_name SkinManager
# roku note 2024-08-06
# make a default skin with all the default values, make merge function to put changed values on top of default skin?

# absolute blabber you can ignore this
# in root, we have a player class with their skin
# upon entering gameplay, give that player variable and apply the skin to each aspect of it (ui manager, hitobjs, etc)
# player variables can be edited through the preference menu (separate from settings menu)
# settings is for changing how the program runs, preferences is for personalization

var skin_info := ["Name", "Author", "Version"]
var filepath: String

# TODO: make this like zachman's implementation? like a get_colour("name") function

var resources := {
	"texture": {
		"note": null,
		"note_overlay": null,
		"roll_middle": null,
		"roll_end": null,
		"roll_tick": null,
		"spinner_warn": null,
		"spinner_inside": null,
		"spinner_outside": null,
	},
	
	"colour": {
		"don": Color("EB452B"),
		"kat": Color("438EAD"),
		"roll": Color("FCB806"),
		
		"late": Color("ff8a8a"),
		"early": Color("8aa7ff"),
		
		"song_progress_back": Color("333333"),
		"song_progress_front": Color("ffffff"),
		"song_progress_skippable": Color("8bff85"),
	}
}

var valid_osu_textures := {
	"taikohitcircle": "note", 
	"taikohitcircleoverlay": "note_overlay", 
	"taiko-roll-middle": "roll_middle",
	"taiko-roll-end": "roll_end",
	"sliderscorepoint": "roll_tick",
	"spinner-warning": "spinner_warn", 
	"spinner-circle": "spinner_inside", 
	"spinner-approachcircle": "spinner_outside",
	}

func _init(file_path = null):
	if file_path:
		# load skin
		var file_names := DirAccess.get_files_at(file_path)
		for key in resources["texture"]:
			resources["texture"][key] = find_texture_from_osu_skin(file_path, file_names, valid_osu_textures.find_key(key))

# TODO: animated textures
func find_texture_from_osu_skin(directory: String, file_names: Array, texture_name: String) -> ImageTexture:
	var wanted_file_name 
	
	for file in file_names:
		# check for files named [texture_name].png, [texture_name]@2x.png, or [texture_name]-0.png
		var prefix_test = file.trim_prefix(texture_name).trim_suffix(".png")
		if prefix_test.begins_with("@") or prefix_test.begins_with("-") or prefix_test.is_empty():
			# if we havent found a file, the first one will do
			if not wanted_file_name:
				wanted_file_name = file
				continue
			
			if wanted_file_name.contains("@2x") and not file.trim_suffix(texture_name).contains("@2x"):
				wanted_file_name = file
				continue
			
			if wanted_file_name.contains("-0"):
				continue
			wanted_file_name = file
	
	# make ImageTexture with the found texture and return it
	var new_texture: ImageTexture
	if wanted_file_name:
		new_texture = ImageLoader.load_image(directory.path_join(wanted_file_name))
	return new_texture
