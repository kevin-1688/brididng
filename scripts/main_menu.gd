extends Control

@onready var title_label: Label = $Layout/TitleLabel
@onready var subtitle_label: Label = $Layout/SubtitleLabel
@onready var multiplayer_button: Button = $Layout/MultiplayerButton
@onready var web_note_label: Label = $Layout/WebNoteLabel
@onready var local_preview_label: Label = $Layout/LocalPreviewLabel
@onready var round1_button: Button = $Layout/Round1Button
@onready var round2_button: Button = $Layout/Round2Button
@onready var round3_button: Button = $Layout/Round3Button
@onready var lang_button: Button = $Layout/LangButton
@onready var quit_button: Button = $Layout/QuitButton

func _ready() -> void:
	Loc.locale_changed.connect(_refresh_text)
	multiplayer_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/lobby.tscn"))
	round1_button.pressed.connect(_go_local.bind("res://scenes/round1_card.tscn"))
	round2_button.pressed.connect(_go_local.bind("res://scenes/round2_echo.tscn"))
	round3_button.pressed.connect(_go_local.bind("res://scenes/round3_dialogue.tscn"))
	lang_button.pressed.connect(func(): Loc.toggle_locale())
	quit_button.pressed.connect(func(): get_tree().quit())
	if Network.is_networked:
		Network.leave()
	if OS.has_feature("web"):
		multiplayer_button.visible = false
		web_note_label.visible = true
	_refresh_text()

func _go_local(scene_path: String) -> void:
	if Network.is_networked:
		Network.leave()
	get_tree().change_scene_to_file(scene_path)

func _refresh_text() -> void:
	title_label.text = "%s." % Loc.t("ui_menu_title")
	subtitle_label.text = Loc.t("ui_menu_subtitle")
	multiplayer_button.text = "🌐 " + Loc.t("ui_menu_multiplayer")
	web_note_label.text = Loc.t("ui_menu_web_note")
	local_preview_label.text = Loc.t("ui_menu_local_preview")
	round1_button.text = "🎭 " + Loc.t("ui_menu_round1")
	round2_button.text = "📰 " + Loc.t("ui_menu_round2")
	round3_button.text = "🗣️ " + Loc.t("ui_menu_round3")
	lang_button.text = Loc.t("ui_button_lang")
	quit_button.text = Loc.t("ui_menu_quit")
