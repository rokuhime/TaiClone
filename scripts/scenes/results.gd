extends Node

onready var taiclone := $"/root" as Root


func _ready() -> void:
	($RightBar/HitCount/GridContainer/AccurateTexture as TextureRect).texture = taiclone.skin.accurate_judgement
	($RightBar/HitCount/GridContainer/FAccurateTexture as TextureRect).texture = taiclone.skin.accurate_judgement
	($RightBar/HitCount/GridContainer/InaccurateTexture as TextureRect).texture = taiclone.skin.inaccurate_judgement
	($RightBar/HitCount/GridContainer/FInaccurateTexture as TextureRect).texture = taiclone.skin.inaccurate_judgement
	($RightBar/HitCount/GridContainer/MissTexture as TextureRect).texture = taiclone.skin.miss_judgement
	($RightBar/HitCount/GridContainer/Late as CanvasItem).self_modulate = taiclone.skin.late_color
	($RightBar/HitCount/GridContainer/Early as CanvasItem).self_modulate = taiclone.skin.early_color
	($RightBar/ErrorBar/Late as CanvasItem).self_modulate = taiclone.skin.late_color
	($RightBar/ErrorBar/Early as CanvasItem).self_modulate = taiclone.skin.early_color
