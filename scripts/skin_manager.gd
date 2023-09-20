extends Node

var colour_don := Color("EB452B")
var colour_kat := Color("438EAD")

@onready var audio_don := load("res://assets/default_skin/h_don.wav")
@onready var audio_kat := load("res://assets/default_skin/h_kat.wav")

@onready var hitin_accurate := load("res://assets/default_skin/taiko-hit300k.png")
@onready var hitin_inaccurate := load("res://assets/default_skin/taiko-hit100k.png")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
