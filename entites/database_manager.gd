class_name DatabaseManager
extends Node

var db := SQLite.new()
const DB_PATH := "user://taiclone.db"

func _ready():
	var db_exists := FileAccess.file_exists(DB_PATH)
	db.path = DB_PATH
	db.open_db()
	if not db_exists:
		initialize()

func initialize() -> void:
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

func query_test(sample):
	# check if theres an existing entry
	# this is stupid. i wish i could search for the hash but thisll do for now
	db.query("select * from charts where chart_title like '%" + sample.chart_info["chart_title"] + "%'")
	var possible_entries := db.query_result
	for entry in possible_entries:
		if entry["hash"] == sample.hash:
			print("\n", entry, "\n")
			return
	print("db entry not found")
	return
