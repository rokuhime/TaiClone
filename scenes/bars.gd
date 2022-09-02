extends Scene

onready var bottom := $Bottom
onready var root_viewport := $"/root" as Root
onready var top := $Top


func _ready() -> void:
	## Comment
	var position_tween := root_viewport.new_tween(SceneTreeTween.new()).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT).set_parallel()

	## Comment
	var _top_tween := position_tween.tween_property(top, "rect_position:y", 0.0, 1).from(-100.0)

	## Comment
	var _bottom_tween := position_tween.tween_property(bottom, "rect_position:y", 980.0, 1).from(1080.0)
