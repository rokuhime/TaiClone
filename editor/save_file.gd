extends Node

onready var obj_container := $"../Main/Display/HitPoint/ObjectContainer"
onready var root_viewport := $"/root" as Root

func map_to_array() -> PoolStringArray:
	var map = []
	#dummy, basically would include all the metadata shit
	map.append(ChartLoader.FUS_VERSION)

	for hit_obj in obj_container.get_children():
		if hit_obj.is_in_group("HitObject"):
			var obj_info := [hit_obj.timing, hit_obj.actual_speed]

			if hit_obj.is_in_group("Barline"):
				obj_info.append(ChartLoader.NoteType.BARLINE)
			
			elif hit_obj.is_in_group("Note"):
				obj_info.append(ChartLoader.NoteType.KAT if hit_obj._is_kat else ChartLoader.NoteType.DON)
				obj_info.append(hit_obj.finisher)

			elif hit_obj.is_in_group("Roll"):
				obj_info.append(ChartLoader.NoteType.ROLL)
				obj_info.append(hit_obj.length)
				obj_info.append(hit_obj.finisher)
				obj_info.append(15 / hit_obj._tick_distance)

			elif hit_obj.is_in_group("SpinnerWarn"):
				obj_info.append(ChartLoader.NoteType.SPINNER)
				obj_info.append(hit_obj.length)
				obj_info.append(hit_obj.end_time)

			elif hit_obj.is_in_group("TimingPoint"):
				obj_info.append(ChartLoader.NoteType.TIMING_POINT)
				obj_info.append(hit_obj.bpm)

			map.append(ChartLoader._csv_line(obj_info))
	return map

func save_map() -> void:
	var f := File.new()
	
	if f.open(root_viewport.game_path.plus_file(ChartLoader.FUS), File.WRITE):
		f.close()
		return
	var fuckgodot: PoolStringArray = map_to_array()
	f.store_string(fuckgodot.join("\n"))
	f.close()
