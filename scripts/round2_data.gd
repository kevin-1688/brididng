extends Node

var packs: Array = []
var cards: Dictionary = {}
var debrief: Array = []

func _ready() -> void:
	_load_packs("res://data/round2_packs.csv")
	_load_cards("res://data/round2_cards.csv")
	_load_debrief("res://data/round2_debrief.csv")

func _load_packs(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Round2Data: cannot open %s" % path)
		return
	f.get_csv_line()
	while f.get_position() < f.get_length():
		var row := f.get_csv_line()
		if row.size() < 4 or row[0] == "":
			continue
		packs.append({"pack_id": row[0], "icon": row[1], "name_key": row[2], "frame_key": row[3]})
		cards[row[0]] = []
	f.close()

func _load_cards(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Round2Data: cannot open %s" % path)
		return
	f.get_csv_line()
	while f.get_position() < f.get_length():
		var row := f.get_csv_line()
		if row.size() < 4 or row[0] == "":
			continue
		var pack_id: String = row[1]
		if not cards.has(pack_id):
			cards[pack_id] = []
		cards[pack_id].append(row[3])
	f.close()

func _load_debrief(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Round2Data: cannot open %s" % path)
		return
	f.get_csv_line()
	while f.get_position() < f.get_length():
		var row := f.get_csv_line()
		if row.size() < 2 or row[0] == "":
			continue
		debrief.append(row[1])
	f.close()
