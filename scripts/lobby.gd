extends Control

enum Mode { SELECT, HOST, JOIN }

@onready var title_label: Label = $Layout/TitleLabel
@onready var lang_button: Button = $Layout/TopBar/LangButton
@onready var back_button: Button = $Layout/TopBar/BackButton

@onready var mode_panel: VBoxContainer = $Layout/ModePanel
@onready var host_mode_button: Button = $Layout/ModePanel/HostModeButton
@onready var join_mode_button: Button = $Layout/ModePanel/JoinModeButton

@onready var host_panel: VBoxContainer = $Layout/HostPanel
@onready var nickname_input_host: LineEdit = $Layout/HostPanel/NicknameInputHost
@onready var create_room_button: Button = $Layout/HostPanel/CreateRoomButton
@onready var ip_info_label: Label = $Layout/HostPanel/IPInfoLabel
@onready var players_title_label_host: Label = $Layout/HostPanel/PlayersTitleLabelHost
@onready var player_list_host: VBoxContainer = $Layout/HostPanel/PlayerListHost
@onready var start_game_button: Button = $Layout/HostPanel/StartGameButton

@onready var join_panel: VBoxContainer = $Layout/JoinPanel
@onready var nickname_input_join: LineEdit = $Layout/JoinPanel/NicknameInputJoin
@onready var ip_input_join: LineEdit = $Layout/JoinPanel/IPInputJoin
@onready var connect_button: Button = $Layout/JoinPanel/ConnectButton
@onready var status_label: Label = $Layout/JoinPanel/StatusLabel
@onready var players_title_label_join: Label = $Layout/JoinPanel/PlayersTitleLabelJoin
@onready var player_list_join: VBoxContainer = $Layout/JoinPanel/PlayerListJoin

var current_mode: int = Mode.SELECT

func _ready() -> void:
	Loc.locale_changed.connect(_refresh_text)
	Network.player_list_changed.connect(_refresh_player_lists)
	Network.connection_failed.connect(_on_connection_failed)
	Network.connected_to_host.connect(_on_connected)

	host_mode_button.pressed.connect(func(): _set_mode(Mode.HOST))
	join_mode_button.pressed.connect(func(): _set_mode(Mode.JOIN))
	create_room_button.pressed.connect(_on_create_room)
	start_game_button.pressed.connect(_on_start_game)
	connect_button.pressed.connect(_on_connect_pressed)
	lang_button.pressed.connect(func(): Loc.toggle_locale())
	back_button.pressed.connect(_on_back)

	_set_mode(Mode.SELECT)
	_refresh_text()
	_refresh_player_lists()

func _set_mode(m: int) -> void:
	current_mode = m
	mode_panel.visible = (m == Mode.SELECT)
	host_panel.visible = (m == Mode.HOST)
	join_panel.visible = (m == Mode.JOIN)

func _on_create_room() -> void:
	var player_name: String = nickname_input_host.text.strip_edges()
	if player_name == "":
		player_name = "Host"
	var ok: bool = Network.host_game(player_name)
	if ok:
		ip_info_label.text = "%s : %d" % [Network.get_local_ip(), Network.DEFAULT_PORT]
		ip_info_label.visible = true
		start_game_button.visible = true
		create_room_button.disabled = true
		nickname_input_host.editable = false
		_refresh_player_lists()

func _on_start_game() -> void:
	GameFlow.start_round1()

func _on_connect_pressed() -> void:
	var player_name: String = nickname_input_join.text.strip_edges()
	if player_name == "":
		player_name = "Player"
	var ip: String = ip_input_join.text.strip_edges()
	if ip == "":
		ip = "127.0.0.1"
	status_label.text = Loc.t("ui_lobby_connecting")
	var ok: bool = Network.join_game(ip, player_name)
	if not ok:
		status_label.text = Loc.t("ui_lobby_connect_failed")
	else:
		connect_button.disabled = true
		nickname_input_join.editable = false
		ip_input_join.editable = false

func _on_connected() -> void:
	status_label.text = Loc.t("ui_lobby_waiting_host")

func _on_connection_failed() -> void:
	status_label.text = Loc.t("ui_lobby_connect_failed")
	connect_button.disabled = false
	nickname_input_join.editable = true
	ip_input_join.editable = true

func _refresh_player_lists() -> void:
	for child in player_list_host.get_children():
		child.queue_free()
	for child in player_list_join.get_children():
		child.queue_free()
	for id in Network.players.keys():
		var lbl1 := Label.new()
		lbl1.text = "• " + str(Network.players[id])
		player_list_host.add_child(lbl1)
		var lbl2 := Label.new()
		lbl2.text = "• " + str(Network.players[id])
		player_list_join.add_child(lbl2)

func _on_back() -> void:
	Network.leave()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _refresh_text() -> void:
	title_label.text = Loc.t("ui_lobby_title")
	host_mode_button.text = Loc.t("ui_lobby_host_mode")
	join_mode_button.text = Loc.t("ui_lobby_join_mode")
	lang_button.text = Loc.t("ui_button_lang")
	back_button.text = Loc.t("ui_button_back_menu")
	create_room_button.text = Loc.t("ui_lobby_create_room")
	start_game_button.text = Loc.t("ui_lobby_start_game")
	players_title_label_host.text = Loc.t("ui_lobby_players")
	players_title_label_join.text = Loc.t("ui_lobby_players")
	nickname_input_host.placeholder_text = Loc.t("ui_lobby_nickname_placeholder")
	nickname_input_join.placeholder_text = Loc.t("ui_lobby_nickname_placeholder")
	ip_input_join.placeholder_text = Loc.t("ui_lobby_ip_placeholder")
	connect_button.text = Loc.t("ui_lobby_connect")
