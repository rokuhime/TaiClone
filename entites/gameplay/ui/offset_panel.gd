extends TimeoutControl

@onready var offset_label := $VBoxContainer/OffsetLabel

func _ready() -> void:
	super()
	# ensure it starts invisible
	modulate = Color(1,1,1,0)

func change_offset_text(new_offset: float) -> void:
	offset_label.text = str(roundi(new_offset * 1000))
	change_active(true)
