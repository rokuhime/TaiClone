extends Node

onready var root_viewport := $"/root" as Root
onready var profile_picture := $Organizer/ProfilePicture as TextureRect
onready var ranking := $Organizer/Rank as TextureRect


func _ready() -> void:
	apply_skin()


## Applies the [member root_viewport]'s [SkinManager] to this [Node]. This method is seen in all [Node]s in the "Skinnables" group.
func apply_skin() -> void:
	profile_picture.texture = root_viewport.skin.mod_sudden_death
	ranking.texture = root_viewport.skin.ranking_s_small
