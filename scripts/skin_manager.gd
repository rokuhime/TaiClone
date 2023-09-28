extends Node

var colour_don := Color("EB452B")
var colour_kat := Color("438EAD")
var colour_roll := Color("FCB806")

@onready var audio_don := load("res://assets/default_skin/h_don.wav")
@onready var audio_kat := load("res://assets/default_skin/h_kat.wav")
@onready var audio_don_f := load("res://assets/default_skin/hf_don.wav")
@onready var audio_kat_f := load("res://assets/default_skin/hf_kat.wav")

@onready var hitin_accurate := load("res://assets/default_skin/taiko-hit300k.png")
@onready var hitin_inaccurate := load("res://assets/default_skin/taiko-hit100k.png")
@onready var hitin_miss := load("res://assets/default_skin/taiko-hit0.png")
