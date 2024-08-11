extends Panel

@onready var index_label := $VBoxContainer/Index
@onready var subtitle_label := $VBoxContainer/Subtitle
var visibility_tween: Tween

func _ready() -> void:
	modulate.a = 0

func _process(delta) -> void:
	# ensure control's visual is correct
	if modulate.a == 0 and visible:
		visible = false
	elif modulate.a > 0 and not visible:
		visible = true

func update_visual(current_index: int, total_count: int) -> void:
	index_label.text = "%s/%s" % [current_index, total_count]
	#subtitle_label.text = sort_type
	
	if visibility_tween:
		visibility_tween.kill()
	visibility_tween = get_tree().create_tween()
	visibility_tween.tween_property(self, "modulate:a", 0.0, 0.5).from(1.0)
