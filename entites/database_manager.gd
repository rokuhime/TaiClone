class_name DatabaseManager
extends Node

# roku note 2024-08-09
# if we use LIKE queries with strings anywhere, we're going to need string escaping to avoid sql injection
# see the conversation you had with barry

var db := SQLite.new()
const DB_PATH := "user://taiclone.db"

# -------- system -------

func _ready():
	initialize_tables()
	restart_db()

# -------- setting up database -------

func initialize_tables() -> void:
	var tables := {}
	
	tables["charts"] = {
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
	
	tables["chart_settings"] = {
		"id": 				{"data_type": "int", "primary_key": true, "not_null": true, "auto_increment": true},
		"local_offset":		{"data_type": "real"},
		"collections":		{"data_type": "int"}, # this is a bitwise (for now) of collection id's!
	}
	
	for table_name in tables.keys():
		db.create_table(table_name, tables[table_name])

func table_exists(table_name: String) -> bool:
	var db_entry := get_db_entry_by_id(table_name, 0)
	if not db_entry:
		return false
	return true

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

func get_db_entry_by_id(table_name: String, id: int) -> Array:
	return db.select_rows(table_name, "id = %s" % id, ["*"])[0]

func add_db_entry(table_name: String, db_entry: Dictionary) -> void:
	db.insert_row(table_name, db_entry)

func update_db_entry(table_name: String, db_entry: Dictionary) -> void:
	if db_entry.is_empty():
		return
	
	var existing_entry := get_db_entry_by_id(table_name, db_entry["id"])
	if existing_entry:
		db.update_rows(table_name, "id = %s" % db_entry["id"], db_entry)
		return
	add_db_entry(table_name, db_entry)

func delete_db_entry(db_entry: Dictionary) -> void:
	db.delete_rows("charts", "id = %s" % db_entry["id"])

# -------- chart interaction -------

func get_all_charts() -> Array:
	db.query("select * from charts")
	return db.query_result

func update_chart(chart: Chart) -> void:
	var existing_entry := get_db_entry(chart)
	if not existing_entry.is_empty():
		db.update_rows("charts", "id = %s" % get_db_entry(chart)["id"], chart_to_db_entry(chart))
		Global.push_console("DatabaseManager", "Updated entry for %s - %s [%s]" % [
						chart.chart_info["song_title"], chart.chart_info["song_artist"], chart.chart_info["chart_title"]],
						-2)
		return
	add_db_entry("charts", chart_to_db_entry(chart))

func exists_in_db(chart: Chart) -> bool:
	db.query_with_bindings("select * from charts where hash = ?", [chart.hash])
	var possible_entries := db.query_result
	for entry in possible_entries:
		if entry["hash"] == chart.hash:
			return true
	return false

# returns the database entry of a chart
func get_db_entry(chart: Chart) -> Dictionary:
	# check if theres an existing entry
	# this is stupid. i wish i could search for the hash but thisll do for now
	db.query_with_bindings("select * from charts where hash = ?", [chart.hash])
	var possible_entries := db.query_result
	for entry in possible_entries:
		if entry["hash"] == chart.hash:
			#print("\n", entry, "\n")
			return entry
	
	Global.push_console("DatabaseManager", "Chart not found in DB!", 1)
	return {}

func clear_invalid_entries() -> void: 
	Global.push_console("DatabaseManager", "Clearing invalid entries...")
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

# -------- converting db entries -------

static func chart_to_db_entry(chart: Chart) -> Dictionary:
	var db_entry := chart.chart_info
	db_entry["file_path"] = chart.file_path
	db_entry["hash"] = chart.hash
	
	# if theres no origin path (origin == .tc), set it to null
	if not db_entry.has("origin_path"):
		db_entry["origin_path"] = null
	
	return db_entry

# generates a chart variable from a database row
static func db_entry_to_chart(db_entry: Dictionary) -> Chart:
	var file_path: String
	var audio: AudioStream
	var background: ImageTexture
	var hash: PackedByteArray
	var chart_info := {}
	
	for key in db_entry.keys():
		match key:
			"file_path":
				file_path = db_entry[key]
			"hash":
				hash = db_entry["hash"] as PackedByteArray
			_:
				chart_info[key] = db_entry[key]
	
	return Chart.new(file_path, chart_info, [], [], hash)
