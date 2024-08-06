class_name SkinManager

var skin_info := ["Name", "Author", "Version"]
var filepath: String

var don_colour := Color("EB452B")
var kat_colour := Color("438EAD")
var roll_colour := Color("FCB806")

var late_colour := Color("ff8a8a")
var early_colour := Color("8aa7ff")

func _init(filepath = null):
	if filepath:
		# load skin
		pass
