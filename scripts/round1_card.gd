extends Control

@onready var title_label: Label = $Layout/TitleLabel
@onready var counter_label: Label = $Layout/TopBar/CounterLabel
@onready var lang_button: Button = $Layout/TopBar/LangButton
@onready var back_button: Button = $Layout/TopBar/BackButton
@onready var name_label: Label = $Layout/NameLabel
@onready var phase_background_label: Label = $Layout/BackgroundCard/BackgroundCardBox/PhaseBackgroundLabel
@onready var background_text: Label = $Layout/BackgroundCard/BackgroundCardBox/BackgroundText
@onready var guess_prompt_label: Label = $Layout/GuessPromptLabel
@onready var reveal_button: Button = $Layout/RevealButton
@onready var monologue_box: PanelContainer = $Layout/MonologueBox
@onready var phase_monologue_label: Label = $Layout/MonologueBox/MonologueInner/PhaseMonologueLabel
@onready var monologue_text: Label = $Layout/MonologueBox/MonologueInner/MonologueText
@onready var nav_bar: HFlowContainer = $Layout/NavBar
@onready var prev_button: Button = $Layout/NavBar/PrevButton
@onready var next_button: Button = $Layout/NavBar/NextButton
@onready var next_round_button: Button = $Layout/NextRoundButton

var current_index: int = 0
var networked: bool = false

func _ready() -> void:
	Loc.locale_changed.connect(_refresh_text)
	reveal_button.pressed.connect(_on_reveal_pressed)
	next_button.pressed.connect(_on_next_pressed)
	prev_button.pressed.connect(_on_prev_pressed)
	lang_button.pressed.connect(_on_lang_pressed)
	back_button.pressed.connect(_on_back_pressed)
	next_round_button.pressed.connect(func(): GameFlow.start_round2())

	networked = Network.is_networked
	if networked:
		_setup_networked()
	else:
		_setup_local()

func _setup_local() -> void:
	nav_bar.visible = true
	next_round_button.visible = false
	counter_label.visible = true
	_show_card(0)

func _setup_networked() -> void:
	nav_bar.visible = false
	next_round_button.visible = Network.is_host
	counter_label.visible = false
	monologue_box.visible = false
	if GameFlow.my_assigned_card_key != "":
		_show_assigned_card(GameFlow.my_assigned_card_key)
	else:
		GameFlow.my_card_assigned.connect(_show_assigned_card, CONNECT_ONE_SHOT)
	_refresh_text()

func _show_assigned_card(card_key: String) -> void:
	for i in range(CardDeck.cards.size()):
		if CardDeck.cards[i].card_key == card_key:
			current_index = i
			break
	monologue_box.visible = false
	_refresh_text()

func _on_reveal_pressed() -> void:
	monologue_box.visible = true

func _on_next_pressed() -> void:
	current_index = (current_index + 1) % CardDeck.cards.size()
	_show_card(current_index)

func _on_prev_pressed() -> void:
	current_index = (current_index - 1 + CardDeck.cards.size()) % CardDeck.cards.size()
	_show_card(current_index)

func _on_lang_pressed() -> void:
	Loc.toggle_locale()

func _on_back_pressed() -> void:
	if networked:
		Network.leave()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _show_card(index: int) -> void:
	monologue_box.visible = false
	_refresh_text()

func _refresh_text() -> void:
	if CardDeck.cards.is_empty():
		return
	var card: Dictionary = CardDeck.cards[current_index]
	title_label.text = Loc.t("ui_round1_title")
	phase_background_label.text = Loc.t("ui_phase_background")
	guess_prompt_label.text = Loc.t("ui_phase_guess_prompt")
	reveal_button.text = Loc.t("ui_button_reveal")
	phase_monologue_label.text = Loc.t("ui_phase_monologue_title")
	lang_button.text = Loc.t("ui_button_lang")
	back_button.text = Loc.t("ui_button_back_menu")
	next_round_button.text = "%s →" % Loc.t("ui_button_next_round")
	name_label.text = "%s  %s" % [card.icon, Loc.t(card.name_key)]
	background_text.text = Loc.t(card.background_key)
	monologue_text.text = Loc.t(card.monologue_key)
	if not networked:
		counter_label.text = "%s %d / %d" % [Loc.t("ui_card_counter"), current_index + 1, CardDeck.cards.size()]
