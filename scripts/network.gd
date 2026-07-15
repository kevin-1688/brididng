extends Node

signal player_list_changed
signal connection_failed
signal connected_to_host
signal disconnected

const DEFAULT_PORT := 8910
const MAX_PLAYERS := 8

var players: Dictionary = {}
var my_name: String = "Player"
var is_host: bool = false
var is_networked: bool = false

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game(player_name: String, port: int = DEFAULT_PORT) -> bool:
	my_name = player_name
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		return false
	multiplayer.multiplayer_peer = peer
	is_host = true
	is_networked = true
	players.clear()
	players[multiplayer.get_unique_id()] = player_name
	player_list_changed.emit()
	return true

func join_game(ip: String, player_name: String, port: int = DEFAULT_PORT) -> bool:
	my_name = player_name
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, port)
	if err != OK:
		return false
	multiplayer.multiplayer_peer = peer
	is_host = false
	is_networked = true
	return true

func get_local_ip() -> String:
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.") or ip.begins_with("10.") or ip.begins_with("172."):
			return ip
	return "127.0.0.1"

func leave() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	players.clear()
	is_networked = false
	is_host = false
	GameFlow.reset_state()

func _on_peer_connected(_id: int) -> void:
	pass

func _on_peer_disconnected(id: int) -> void:
	if players.has(id):
		players.erase(id)
	if is_host:
		_sync_player_list.rpc(players)
	player_list_changed.emit()

func _on_connected_to_server() -> void:
	_submit_name.rpc_id(1, my_name)
	connected_to_host.emit()

func _on_connection_failed() -> void:
	is_networked = false
	connection_failed.emit()

func _on_server_disconnected() -> void:
	is_networked = false
	is_host = false
	players.clear()
	disconnected.emit()

@rpc("any_peer", "reliable")
func _submit_name(pname: String) -> void:
	if not is_host:
		return
	var sender := multiplayer.get_remote_sender_id()
	players[sender] = pname
	_sync_player_list.rpc(players)

@rpc("authority", "reliable", "call_local")
func _sync_player_list(list: Dictionary) -> void:
	players = list
	player_list_changed.emit()
