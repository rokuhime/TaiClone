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

var don_colour := Color("EB452B")
var kat_colour := Color("438EAD")
var roll_colour := Color("FCB806")

var late_colour := Color("ff8a8a")
var early_colour := Color("8aa7ff")

var song_progress_back := Color("333333")
var song_progress_front := Color("ffffff")
var song_progress_skippable := Color("8bff85")

func _init(filepath = null):
	if filepath:
		# load skin
		pass
