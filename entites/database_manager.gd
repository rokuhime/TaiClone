class_name DatabaseManager
extends Node

var db := SQLite.new()
const DB_PATH := "user://taiclone.db"

# -------- system -------

func _ready():
	restart_db()

# -------- setting up database -------

func initialize_tables() -> void:
	var chart_table := {
		"id": 				{"data_type": "int", "primary_key": true, "not_null": true, "auto_increment": true},
		"song_title": 		{"data_type": "text"},
		"song_artist": 		{"data_type": "text"},
		"chart_title": 		{"data_type": "text"},
		"chart_artist": 	{"data_type": "text"},
		
		"file_path": 		{"data_type": "text"},
		"origin": 			{"data_type": "text"},
		"origin_path":		{"data_type": "text"}, #(optional, for origins outside of taiclone)
		"hash": 			{"data_type": "blob"},
		"audio_path":		{"data_type": "text"},
		"background_path":	{"data_type": "text"},
		"preview_point":	{"data_type": "real"},
	}
	
	db.create_table("charts", chart_table)

# close and reopen db to check if its been edited outside of the program
func restart_db() -> void:
	db.close_db()
	var db_exists := FileAccess.file_exists(DB_PATH)
	db.path = DB_PATH
	db.open_db()
	if not db_exists:
		initialize_tables()
	Global.push_console("DatabaseManager", "Database restarted!")

# -------- database interaction -------

func add_chart(chart: Chart) -> void:
	# fill in db dictionary
	var db_entry := chart.chart_info
	db_entry["file_path"] = chart.file_path
	db_entry["hash"] = chart.hash
	
	# if theres no origin path (origin == .tc), set it to null
	if not db_entry.has("origin_path"):
		db_entry["origin_path"] = null
	
	# add the entry
	db.insert_row("charts", db_entry)
	Global.push_console("DatabaseManager", "Adding entry for %s - %s [%s]" % [
					chart.chart_info["song_title"], chart.chart_info["song_artist"], chart.chart_info["chart_title"]],)

func update_chart(chart: Chart) -> void:
	var db_entry := get_db_entry(chart)
	if not db_entry.is_empty():
		db.update_rows("charts", "id = %s" % get_db_entry(chart)["id"], chart_to_db_entry(chart))
		Global.push_console("DatabaseManager", "Updated entry for %s - %s [%s]" % [
						chart.chart_info["song_title"], chart.chart_info["song_artist"], chart.chart_info["chart_title"]],
						-2)
	else:
		add_chart(chart)

func exists_in_db(chart: Chart) -> bool:
	db.query("select * from charts where chart_title like '%" + chart.chart_info["chart_title"] + "%'")
	var possible_entries := db.query_result
	for entry in possible_entries:
		if entry["hash"] == chart.hash:
			return true
	return false

# returns the database entry of a chart
func get_db_entry(chart: Chart) -> Dictionary:
	# check if theres an existing entry
	# this is stupid. i wish i could search for the hash but thisll do for now
	db.query("select * from charts where chart_title like '%" + chart.chart_info["chart_title"] + "%'")
	var possible_entries := db.query_result
	for entry in possible_entries:
		if entry["hash"] == chart.hash:
			#print("\n", entry, "\n")
			return entry
	
	Global.push_console("DatabaseManager", "Chart not found in DB!", 1)
	return {}

func delete_db_entry(db_entry: Dictionary) -> void:
	db.delete_rows("charts", "id = %s" % db_entry["id"])

func get_all_charts() -> Array:
	db.query("select * from charts")
	return db.query_result

func clear_invalid_entries() -> void: 
	var db_charts := Global.database_manager.get_all_charts()
	var existing_hashes := []
	
	for db_entry in db_charts:
		# if the origin file is gone, delete the convert and the db entry
		if not FileAccess.file_exists(db_entry["origin_path"]): 
			Global.push_console("DatabaseManager", "Origin not found, removing: %s - %s [%s]" % [
				db_entry["song_title"], db_entry["song_artist"], db_entry["chart_title"]],
				 1)
			DirAccess.remove_absolute(db_entry["file_path"])
			Global.database_manager.delete_db_entry(db_entry)
			continue
		
		# if an origin exists but the converts gone, remake the convert and update
		elif not FileAccess.file_exists(db_entry["file_path"]):
			Global.push_console("DatabaseManager", "Convert not found, recreating and updating: %s - %s [%s]" % [
				db_entry["song_title"], db_entry["song_artist"], db_entry["chart_title"]],
				 1)
			var new_convert := ChartLoader.get_chart_path(db_entry["origin_path"])
			update_chart(ChartLoader.get_tc_metadata(new_convert))
			continue
		
		# if the chart already exists
		if existing_hashes.has(Global.get_hash(db_entry["file_path"])):
			Global.push_console("DatabaseManager", "Duplicate entry found, being removed: %s - %s [%s]" % [
				db_entry["song_title"], db_entry["song_artist"], db_entry["chart_title"]],
				 1)
			Global.database_manager.delete_db_entry(db_entry)
			continue
		
		existing_hashes.append(Global.get_hash(db_entry["file_path"]))

# -------- parsing database info -------

func chart_to_db_entry(chart: Chart) -> Dictionary:
	var db_entry := chart.chart_info
	db_entry["file_path"] = chart.file_path
	db_entry["hash"] = chart.hash
	return db_entry

# generates a chart variable from a database row
func db_entry_to_chart(db_entry: Dictionary) -> Chart:
	var file_path: String
	var audio: AudioStream
	var background: ImageTexture
	var hash: PackedByteArray
	var chart_info := {}
	
	for key in db_entry.keys():
		match key:
			"file_path":
				file_path = db_entry[key]
			"audio_path":
				if db_entry[key] != null:
					audio = AudioLoader.load_file(db_entry[key])
			"background_path":
				if db_entry[key] != null:
					background = ImageLoader.load_image(db_entry[key])
			"hash":
				hash = db_entry["hash"] as PackedByteArray
			_:
				chart_info[key] = db_entry[key]
	
	return Chart.new(file_path, audio, background, chart_info, [], [], hash)
