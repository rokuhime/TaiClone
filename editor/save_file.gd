extends Node

onready var obj_container := $"../Main/Display/HitPoint/ObjectContainer"
onready var root_viewport := $"/root" as Root

func map_to_array() -> PoolStringArray:
	var map: PoolStringArray = []
	var lol := []

	# goofy ah sorting
	for hit_obj in obj_container.get_children():
		var i := 0
		while i < lol.size():
			if (hit_obj.timing < lol[i].timing) or (hit_obj.timing == lol[i].timing and hit_obj.is_in_group("TimingPoint")):
				break
			i += 1
		if i == lol.size():
			lol.append(hit_obj)
		else:
			lol.insert(i, hit_obj)

	#dummy, basically would include all the metadata shit
	map.append(ChartLoader.FUS_VERSION)
	map.append(root_viewport.title)
	map.append(root_viewport.preview)
	map.append(root_viewport.od)
	map.append(root_viewport.folder_path)
	map.append(root_viewport.difficulty_name)
	map.append(root_viewport.charter)
	map.append(root_viewport.bg_file_name)
	map.append(root_viewport.audio_file_name)
	map.append(root_viewport.artist)

	var cur_bpm := 0.0
	var cur_bpm_timing := 0.0

	for hit_obj in lol:
		if hit_obj.is_in_group("HitObject"):

			var obj_info := []

			if hit_obj.is_in_group("TimingPoint"):
				obj_info.append(hit_obj.timing * 1000)
				obj_info.append(hit_obj.bpm)
				cur_bpm_timing = hit_obj.timing
				cur_bpm = hit_obj.bpm
				obj_info.append(ChartLoader.NoteType.TIMING_POINT)
				obj_info.append(int(hit_obj.is_kiai))
			
			else:
				obj_info.append((hit_obj.timing - cur_bpm_timing) / 60 * cur_bpm)
				obj_info.append(hit_obj.actual_speed / 5.7 / cur_bpm if cur_bpm else 0)

				if hit_obj.is_in_group("Barline"):
					obj_info.append(ChartLoader.NoteType.BARLINE)
				
				elif hit_obj.is_in_group("Note"):
					obj_info.append(ChartLoader.NoteType.KAT if hit_obj._is_kat else ChartLoader.NoteType.DON)
					obj_info.append(int(hit_obj.finisher))

				elif hit_obj.is_in_group("Roll"):
					obj_info.append(ChartLoader.NoteType.ROLL)
					obj_info.append(hit_obj.length)
					obj_info.append(int(hit_obj.finisher))
					obj_info.append(15 / hit_obj._tick_distance)

				elif hit_obj.is_in_group("SpinnerWarn"):
					obj_info.append(ChartLoader.NoteType.SPINNER)
					obj_info.append(hit_obj.length)
					obj_info.append(hit_obj.end_time)

			map.append(ChartLoader._csv_line(obj_info).join(","))
			lol[hit_obj.timing] = ChartLoader._csv_line(obj_info).join(",")
	
	return map

func save_map() -> void:
	var f := File.new()
	
	if f.open(root_viewport.game_path.plus_file(ChartLoader.FUS), File.WRITE):
		f.close()
		return
	#var fuckgodot: PoolStringArray = map_to_array()
	f.store_string(map_to_array().join("\n"))
	f.close()
