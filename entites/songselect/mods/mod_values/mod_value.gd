class_name ModValue
extends Node

@onready var title = $Title
func _ready():
	title.text = name
