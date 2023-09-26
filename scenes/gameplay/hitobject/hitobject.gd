class_name HitObject
extends Control

@export var time := 0.0
@export var speed := 0.0

var state := 1

#enum VELOCITIES {TAIKO, MANIA}
#var velocity_type := 0

## acts as _init() function, see gameplay load_chart()
func change_properties(new_timing : float, new_speed : float, new_kat : bool, new_finisher := false) -> void:
	time = new_timing
	speed = new_speed

## moves hitobject across playfield
func move(cur_time : float) -> void:
	position.x = speed * (time - cur_time)

## checks if given inputs/time, the object was hit
## made to be overwritten in each HitObject type
func hit(inputs, cur_time : float) -> int:
	return 0 # miss
