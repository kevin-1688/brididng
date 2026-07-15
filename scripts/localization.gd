extends Node

signal locale_changed

var locales: Array = []
var current_locale: String = "zh_TW"
var _strings: Dictionary = {}

func _ready() -> void:
	_load_csv("res://data/strings.csv")

func _load_csv(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Localization: cannot open %s" % path)
		return
	var header := f.get_csv_line()
	locales = header.slice(1)
	while f.get_position() < f.get_length():
		var row := f.get_csv_line()
		if row.size() < 2 or row[0] == "":
			continue
		var key := row[0]
		var entry := {}
		for i in range(1, row.size()):
			if i - 1 < locales.size():
				entry[locales[i - 1]] = row[i].replace("\\n", "\n")
		_strings[key] = entry
	f.close()

func t(key: String) -> String:
	if not _strings.has(key):
		return key
	var entry: Dictionary = _strings[key]
	if entry.has(current_locale):
		return entry[current_locale]
	if entry.has("en"):
		return entry["en"]
	return key

func set_locale(loc: String) -> void:
	if loc == current_locale or not locales.has(loc):
		return
	current_locale = loc
	locale_changed.emit()

func toggle_locale() -> void:
	set_locale("en" if current_locale == "zh_TW" else "zh_TW")
