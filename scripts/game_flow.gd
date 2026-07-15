extends Node

signal round_changed(round_name: String)
signal my_card_assigned(card_key: String)
signal my_pack_assigned(pack_id: String)
signal phase_changed(phase_index: int)
signal timer_started(end_unix_ms: int)
signal timer_cancelled
signal r2_mode_changed(mode_name: String)

var current_round: String = "lobby"
var my_assigned_card_key: String = ""
var my_assigned_pack_id: String = ""
var current_phase_index: int = 0
var timer_end_unix_ms: int = 0
var current_r2_mode: String = "browse"

func start_round1() -> void:
	if not Network.is_host:
		return
	var keys: Array = []
	for c in CardDeck.cards:
		keys.append(c.card_key)
	keys.shuffle()
	var peer_ids: Array = Network.players.keys()
	var my_id := multiplayer.get_unique_id()
	for i in range(peer_ids.size()):
		var key: String = keys[i % keys.size()]
		if peer_ids[i] == my_id:
			my_assigned_card_key = key
			my_card_assigned.emit(key)
		else:
			_receive_card.rpc_id(peer_ids[i], key)
	_set_round.rpc("round1")

func start_round2() -> void:
	if not Network.is_host:
		return
	var pack_ids: Array = []
	for p in Round2Data.packs:
		pack_ids.append(p.pack_id)
	pack_ids.shuffle()
	var peer_ids: Array = Network.players.keys()
	var my_id := multiplayer.get_unique_id()
	for i in range(peer_ids.size()):
		var pid: String = pack_ids[i % pack_ids.size()]
		if peer_ids[i] == my_id:
			my_assigned_pack_id = pid
			my_pack_assigned.emit(pid)
		else:
			_receive_pack.rpc_id(peer_ids[i], pid)
	_set_round.rpc("round2")

func start_round3() -> void:
	if not Network.is_host:
		return
	current_phase_index = 0
	_set_round.rpc("round3")

func return_to_lobby() -> void:
	if not Network.is_host:
		return
	_set_round.rpc("lobby")

@rpc("authority", "reliable", "call_local")
func _set_round(round_name: String) -> void:
	current_round = round_name
	round_changed.emit(round_name)
	match round_name:
		"round1":
			get_tree().change_scene_to_file("res://scenes/round1_card.tscn")
		"round2":
			get_tree().change_scene_to_file("res://scenes/round2_echo.tscn")
		"round3":
			get_tree().change_scene_to_file("res://scenes/round3_dialogue.tscn")
		"lobby":
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

@rpc("authority", "reliable")
func _receive_card(card_key: String) -> void:
	my_assigned_card_key = card_key
	my_card_assigned.emit(card_key)

@rpc("authority", "reliable")
func _receive_pack(pack_id: String) -> void:
	my_assigned_pack_id = pack_id
	my_pack_assigned.emit(pack_id)

func set_phase(i: int) -> void:
	if not Network.is_host:
		return
	_sync_phase.rpc(i)

@rpc("authority", "reliable", "call_local")
func _sync_phase(i: int) -> void:
	current_phase_index = i
	phase_changed.emit(i)

func set_r2_mode(mode_name: String) -> void:
	if not Network.is_host:
		return
	_sync_r2_mode.rpc(mode_name)

@rpc("authority", "reliable", "call_local")
func _sync_r2_mode(mode_name: String) -> void:
	current_r2_mode = mode_name
	r2_mode_changed.emit(mode_name)

func start_timer(duration_sec: int) -> void:
	if not Network.is_host:
		return
	var end_unix_ms := int(Time.get_unix_time_from_system() * 1000.0) + duration_sec * 1000
	_sync_timer.rpc(end_unix_ms)

@rpc("authority", "reliable", "call_local")
func _sync_timer(end_unix_ms: int) -> void:
	timer_end_unix_ms = end_unix_ms
	timer_started.emit(end_unix_ms)

func cancel_timer() -> void:
	if not Network.is_host:
		return
	_sync_timer_cancel.rpc()

@rpc("authority", "reliable", "call_local")
func _sync_timer_cancel() -> void:
	timer_end_unix_ms = 0
	timer_cancelled.emit()

func reset_state() -> void:
	current_round = "lobby"
	my_assigned_card_key = ""
	my_assigned_pack_id = ""
	current_phase_index = 0
	timer_end_unix_ms = 0
	current_r2_mode = "browse"
