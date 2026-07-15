extends Node

var phases: Array = []
var topics: Array = []
var debrief: Array = []

func _ready() -> void:
	_load_phases("res://data/round3_phases.csv")
	_load_topics("res://data/round3_topics.csv")
	_load_debrief("res://data/round3_debrief.csv")

func _load_phases(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Round3Data: cannot open %s" % path)
		return
	f.get_csv_line()
	while f.get_position() < f.get_length():
		var row := f.get_csv_line()
		if row.size() < 5 or row[0] == "":
			continue
		phases.append({
			"id": int(row[0]),
			"order": int(row[1]),
			"phase_type": row[2],
			"title_key": row[3],
			"body_key": row[4],
		})
	f.close()

func _load_topics(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Round3Data: cannot open %s" % path)
		return
	f.get_csv_line()
	while f.get_position() < f.get_length():
		var row := f.get_csv_line()
		if row.size() < 4 or row[0] == "":
			continue
		topics.append({"icon": row[1], "name_key": row[2], "framing_key": row[3]})
	f.close()

func _load_debrief(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Round3Data: cannot open %s" % path)
		return
	f.get_csv_line()
	while f.get_position() < f.get_length():
		var row := f.get_csv_line()
		if row.size() < 2 or row[0] == "":
			continue
		debrief.append(row[1])
	f.close()
