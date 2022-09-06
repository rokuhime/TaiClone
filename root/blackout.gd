extends Scene

## Comment
var _modulate_tween := SceneTreeTween.new()

onready var root_viewport := $"/root" as Root


func _ready() -> void:
	GlobalTools.send_signal(root_viewport, "finished", _tween_modulate(1), "remove_blackout")


## See [Scene].
func scene_removed() -> void:
	GlobalTools.send_signal(self, "finished", _tween_modulate(0), "queue_free")


## Comment
func _tween_modulate(final_val: float) -> PropertyTweener:
	_modulate_tween = root_viewport.new_tween(_modulate_tween).set_ease(Tween.EASE_OUT)
	return _modulate_tween.tween_property(self, "modulate:a", final_val, 0.4).from(1 - final_val)
