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

func _init(filepath = null):
	if filepath:
		# load skin
		pass
