extends Node

var cards: Array = []

func _ready() -> void:
	_load_csv("res://data/cards_round1.csv")

func _load_csv(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("CardDeck: cannot open %s" % path)
		return
	f.get_csv_line() # header
	while f.get_position() < f.get_length():
		var row := f.get_csv_line()
		if row.size() < 7 or row[0] == "":
			continue
		cards.append({
			"id": int(row[0]),
			"card_key": row[1],
			"generation_tag": row[2],
			"icon": row[3],
			"name_key": row[4],
			"background_key": row[5],
			"monologue_key": row[6],
		})
	f.close()
