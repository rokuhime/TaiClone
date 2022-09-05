extends Scene

## Comment
var _active := false

## Comment
var _position_tween := SceneTreeTween.new()

onready var root_viewport := $"/root" as Root


func _ready() -> void:
	_tween_position()


## See [Scene].
func scene_removed() -> void:
	_tween_position()


## Comment
func _tween_position() -> void:
	_position_tween = root_viewport.new_tween(_position_tween).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT).set_parallel()
	_active = not _active

	## Comment
	var _left_tween := _position_tween.tween_property(self, "margin_left", -rect_size.x if _active else 0.0, 1)

	## Comment
	var _right_tween := _position_tween.tween_property(self, "margin_right", 0.0 if _active else rect_size.x, 1)

	if not _active:
		GlobalTools.send_signal(self, "finished", _position_tween, "queue_free")
