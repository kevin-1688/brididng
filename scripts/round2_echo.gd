extends Control

enum Mode { BROWSE, TRUTH, DEBRIEF }

@onready var title_label: Label = $Layout/TitleLabel
@onready var lang_button: Button = $Layout/TopBar/LangButton
@onready var back_button: Button = $Layout/TopBar/BackButton

@onready var browse_button: Button = $Layout/ModeBar/BrowseButton
@onready var truth_button: Button = $Layout/ModeBar/TruthButton
@onready var debrief_button: Button = $Layout/ModeBar/DebriefButton

@onready var browse_section: VBoxContainer = $Layout/BrowseSection
@onready var pack_tabs: HBoxContainer = $Layout/BrowseSection/PackTabs
@onready var pack_name_label: Label = $Layout/BrowseSection/PackNameLabel
@onready var card_text_label: Label = $Layout/BrowseSection/CardPanel/CardText
@onready var card_counter_label: Label = $Layout/BrowseSection/CardNav/CardCounterLabel
@onready var prev_button: Button = $Layout/BrowseSection/CardNav/PrevButton
@onready var next_button: Button = $Layout/BrowseSection/CardNav/NextButton
@onready var facilitator_note_button: Button = $Layout/BrowseSection/FacilitatorNoteButton
@onready var facilitator_note_text: Label = $Layout/BrowseSection/FacilitatorNoteText

@onready var truth_section: VBoxContainer = $Layout/TruthSection
@onready var truth_title_label: Label = $Layout/TruthSection/TruthTitleLabel
@onready var truth_text_label: Label = $Layout/TruthSection/TruthPanel/TruthText

@onready var debrief_section: VBoxContainer = $Layout/DebriefSection
@onready var debrief_title_label: Label = $Layout/DebriefSection/DebriefTitleLabel
@onready var debrief_list: VBoxContainer = $Layout/DebriefSection/DebriefList

@onready var next_round_button: Button = $Layout/NextRoundButton

var current_mode: int = Mode.BROWSE
var current_pack_index: int = 0
var current_card_index: int = 0
var pack_buttons: Array = []
var networked: bool = false

func _ready() -> void:
	Loc.locale_changed.connect(_refresh_text)
	_build_pack_tabs()
	_build_debrief_list()

	prev_button.pressed.connect(_on_prev)
	next_button.pressed.connect(_on_next)
	facilitator_note_button.pressed.connect(_on_toggle_note)
	lang_button.pressed.connect(func(): Loc.toggle_locale())
	back_button.pressed.connect(_on_back_pressed)
	next_round_button.pressed.connect(func(): GameFlow.start_round3())

	networked = Network.is_networked

	if networked:
		browse_button.pressed.connect(func(): GameFlow.set_r2_mode("browse"))
		truth_button.pressed.connect(func(): GameFlow.set_r2_mode("truth"))
		debrief_button.pressed.connect(func(): GameFlow.set_r2_mode("debrief"))
		GameFlow.r2_mode_changed.connect(_on_r2_mode_changed)
		next_round_button.visible = Network.is_host
		pack_tabs.visible = false
		facilitator_note_button.visible = Network.is_host
		facilitator_note_text.visible = false
		var assigned_index := 0
		if GameFlow.my_assigned_pack_id != "":
			for i in range(Round2Data.packs.size()):
				if Round2Data.packs[i].pack_id == GameFlow.my_assigned_pack_id:
					assigned_index = i
					break
			_show_pack(assigned_index)
		else:
			GameFlow.my_pack_assigned.connect(_on_pack_assigned, CONNECT_ONE_SHOT)
		_set_mode(Mode.BROWSE)
	else:
		browse_button.pressed.connect(func(): _set_mode(Mode.BROWSE))
		truth_button.pressed.connect(func(): _set_mode(Mode.TRUTH))
		debrief_button.pressed.connect(func(): _set_mode(Mode.DEBRIEF))
		next_round_button.visible = false
		_set_mode(Mode.BROWSE)
		_show_pack(0)

func _on_pack_assigned(pack_id: String) -> void:
	for i in range(Round2Data.packs.size()):
		if Round2Data.packs[i].pack_id == pack_id:
			_show_pack(i)
			return

func _on_r2_mode_changed(mode_name: String) -> void:
	match mode_name:
		"browse": _set_mode(Mode.BROWSE)
		"truth": _set_mode(Mode.TRUTH)
		"debrief": _set_mode(Mode.DEBRIEF)

func _build_pack_tabs() -> void:
	for i in range(Round2Data.packs.size()):
		var btn := Button.new()
		btn.theme_type_variation = &"TabButton"
		btn.toggle_mode = true
		btn.pressed.connect(_on_pack_selected.bind(i))
		pack_tabs.add_child(btn)
		pack_buttons.append(btn)

func _on_pack_selected(i: int) -> void:
	_show_pack(i)

func _show_pack(i: int) -> void:
	current_pack_index = i
	current_card_index = 0
	facilitator_note_text.visible = false
	for j in range(pack_buttons.size()):
		pack_buttons[j].button_pressed = (j == i)
	_refresh_text()

func _on_prev() -> void:
	var pack: Dictionary = Round2Data.packs[current_pack_index]
	var list: Array = Round2Data.cards[pack.pack_id]
	current_card_index = (current_card_index - 1 + list.size()) % list.size()
	_refresh_text()

func _on_next() -> void:
	var pack: Dictionary = Round2Data.packs[current_pack_index]
	var list: Array = Round2Data.cards[pack.pack_id]
	current_card_index = (current_card_index + 1) % list.size()
	_refresh_text()

func _on_toggle_note() -> void:
	facilitator_note_text.visible = not facilitator_note_text.visible

func _on_back_pressed() -> void:
	if networked:
		Network.leave()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _set_mode(m: int) -> void:
	current_mode = m
	browse_section.visible = (m == Mode.BROWSE)
	truth_section.visible = (m == Mode.TRUTH)
	debrief_section.visible = (m == Mode.DEBRIEF)
	browse_button.button_pressed = (m == Mode.BROWSE)
	truth_button.button_pressed = (m == Mode.TRUTH)
	debrief_button.button_pressed = (m == Mode.DEBRIEF)

func _build_debrief_list() -> void:
	for key in Round2Data.debrief:
		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.set_meta("key", key)
		debrief_list.add_child(lbl)

func _refresh_text() -> void:
	title_label.text = Loc.t("ui_round2_title")
	browse_button.text = Loc.t("ui_mode_browse")
	truth_button.text = Loc.t("ui_button_ground_truth")
	debrief_button.text = Loc.t("ui_button_debrief")
	lang_button.text = Loc.t("ui_button_lang")
	back_button.text = Loc.t("ui_button_back_menu")
	facilitator_note_button.text = Loc.t("ui_button_facilitator_note")
	next_round_button.text = "%s →" % Loc.t("ui_button_next_round")
	truth_title_label.text = Loc.t("ui_round2_ground_truth_title")
	truth_text_label.text = Loc.t("r2_ground_truth")
	debrief_title_label.text = Loc.t("ui_round2_debrief_title")

	if Round2Data.packs.size() > 0:
		var pack: Dictionary = Round2Data.packs[current_pack_index]
		pack_name_label.text = Loc.t(pack.name_key)
		facilitator_note_text.text = Loc.t(pack.frame_key)
		for i in range(pack_buttons.size()):
			pack_buttons[i].text = "%s %s" % [Round2Data.packs[i].icon, Loc.t(Round2Data.packs[i].name_key)]
		var list: Array = Round2Data.cards[pack.pack_id]
		if list.size() > 0:
			card_text_label.text = Loc.t(list[current_card_index])
			card_counter_label.text = "%d / %d" % [current_card_index + 1, list.size()]

	for child in debrief_list.get_children():
		child.text = "• " + Loc.t(child.get_meta("key"))
