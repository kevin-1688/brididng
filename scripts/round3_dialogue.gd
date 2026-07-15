extends Control

const TIMER_SECONDS := 90

@onready var title_label: Label = $Layout/TitleLabel
@onready var phase_counter_label: Label = $Layout/TopBar/PhaseCounterLabel
@onready var lang_button: Button = $Layout/TopBar/LangButton
@onready var back_button: Button = $Layout/TopBar/BackButton

@onready var content_section: VBoxContainer = $Layout/ContentSection
@onready var phase_title_label: Label = $Layout/ContentSection/PhaseTitleLabel
@onready var phase_body_label: Label = $Layout/ContentSection/ContentPanel/PhaseBodyLabel

@onready var topics_section: VBoxContainer = $Layout/TopicsSection
@onready var topics_title_label: Label = $Layout/TopicsSection/TopicsTitleLabel
@onready var topic_list: VBoxContainer = $Layout/TopicsSection/TopicList
@onready var topic_panel: PanelContainer = $Layout/TopicsSection/TopicPanel
@onready var topic_framing_label: Label = $Layout/TopicsSection/TopicPanel/TopicFramingLabel

@onready var debrief_section: VBoxContainer = $Layout/DebriefSection
@onready var debrief_title_label: Label = $Layout/DebriefSection/DebriefTitleLabel
@onready var debrief_list: VBoxContainer = $Layout/DebriefSection/DebriefList

@onready var timer_label: Label = $Layout/TimerPanel/TimerBar/TimerLabel
@onready var timer_start_button: Button = $Layout/TimerPanel/TimerBar/TimerStartButton
@onready var timer_reset_button: Button = $Layout/TimerPanel/TimerBar/TimerResetButton
@onready var countdown_timer: Timer = $CountdownTimer

@onready var prev_phase_button: Button = $Layout/NavBar/PrevPhaseButton
@onready var next_phase_button: Button = $Layout/NavBar/NextPhaseButton

var current_phase_index: int = 0
var seconds_left: int = TIMER_SECONDS
var timer_running: bool = false
var selected_topic_index: int = -1
var networked: bool = false

func _ready() -> void:
	Loc.locale_changed.connect(_refresh_text)
	lang_button.pressed.connect(func(): Loc.toggle_locale())
	back_button.pressed.connect(_on_back_pressed)
	countdown_timer.timeout.connect(_on_timer_tick)

	_build_topic_buttons()
	_build_debrief_list()

	networked = Network.is_networked

	if networked:
		prev_phase_button.visible = Network.is_host
		next_phase_button.visible = Network.is_host
		timer_start_button.visible = Network.is_host
		timer_reset_button.visible = Network.is_host
		prev_phase_button.pressed.connect(func(): GameFlow.set_phase(max(0, current_phase_index - 1)))
		next_phase_button.pressed.connect(func(): GameFlow.set_phase(min(Round3Data.phases.size() - 1, current_phase_index + 1)))
		timer_start_button.pressed.connect(func(): GameFlow.start_timer(TIMER_SECONDS))
		timer_reset_button.pressed.connect(func(): GameFlow.cancel_timer())
		GameFlow.phase_changed.connect(_show_phase)
		GameFlow.timer_started.connect(_on_networked_timer_started)
		GameFlow.timer_cancelled.connect(_on_networked_timer_cancelled)
		_show_phase(GameFlow.current_phase_index)
	else:
		prev_phase_button.pressed.connect(_on_prev_phase)
		next_phase_button.pressed.connect(_on_next_phase)
		timer_start_button.pressed.connect(_on_timer_start_pressed)
		timer_reset_button.pressed.connect(_on_timer_reset)
		_show_phase(0)

func _build_topic_buttons() -> void:
	for i in range(Round3Data.topics.size()):
		var btn := Button.new()
		btn.theme_type_variation = &"TabButton"
		btn.toggle_mode = true
		btn.pressed.connect(_on_topic_selected.bind(i))
		topic_list.add_child(btn)

func _on_topic_selected(i: int) -> void:
	selected_topic_index = i
	for j in range(topic_list.get_child_count()):
		topic_list.get_child(j).button_pressed = (j == i)
	topic_framing_label.text = Loc.t(Round3Data.topics[i].framing_key)
	topic_panel.visible = true

func _build_debrief_list() -> void:
	for key in Round3Data.debrief:
		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.set_meta("key", key)
		debrief_list.add_child(lbl)

func _on_prev_phase() -> void:
	current_phase_index = max(0, current_phase_index - 1)
	_show_phase(current_phase_index)

func _on_next_phase() -> void:
	current_phase_index = min(Round3Data.phases.size() - 1, current_phase_index + 1)
	_show_phase(current_phase_index)

func _on_back_pressed() -> void:
	if networked:
		Network.leave()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _show_phase(i: int) -> void:
	current_phase_index = i
	var phase: Dictionary = Round3Data.phases[i]
	content_section.visible = phase.phase_type == "text"
	topics_section.visible = phase.phase_type == "topics"
	debrief_section.visible = phase.phase_type == "debrief"
	if phase.phase_type == "topics":
		topic_panel.visible = false
		selected_topic_index = -1
		for j in range(topic_list.get_child_count()):
			topic_list.get_child(j).button_pressed = false
	_refresh_text()

func _on_timer_start_pressed() -> void:
	if timer_running:
		countdown_timer.stop()
		timer_running = false
		timer_start_button.text = Loc.t("ui_button_start_timer")
	else:
		countdown_timer.start()
		timer_running = true
		timer_start_button.text = Loc.t("ui_button_pause_timer")

func _on_timer_reset() -> void:
	countdown_timer.stop()
	timer_running = false
	seconds_left = TIMER_SECONDS
	timer_label.text = str(seconds_left)
	timer_start_button.text = Loc.t("ui_button_start_timer")

func _on_timer_tick() -> void:
	if networked:
		var remaining_ms: int = GameFlow.timer_end_unix_ms - int(Time.get_unix_time_from_system() * 1000.0)
		if remaining_ms <= 0:
			countdown_timer.stop()
			timer_label.text = Loc.t("ui_timer_done")
		else:
			timer_label.text = str(int(ceil(remaining_ms / 1000.0)))
		return
	seconds_left -= 1
	if seconds_left <= 0:
		seconds_left = 0
		countdown_timer.stop()
		timer_running = false
		timer_label.text = Loc.t("ui_timer_done")
		timer_start_button.text = Loc.t("ui_button_start_timer")
	else:
		timer_label.text = str(seconds_left)

func _on_networked_timer_started(_end_unix_ms: int) -> void:
	countdown_timer.stop()
	countdown_timer.start(1.0)
	_on_timer_tick()

func _on_networked_timer_cancelled() -> void:
	countdown_timer.stop()
	timer_label.text = str(TIMER_SECONDS)

func _refresh_text() -> void:
	title_label.text = Loc.t("ui_round3_title")
	lang_button.text = Loc.t("ui_button_lang")
	back_button.text = Loc.t("ui_button_back_menu")
	timer_reset_button.text = Loc.t("ui_button_reset_timer")
	if not networked and not timer_running and seconds_left == TIMER_SECONDS:
		timer_start_button.text = Loc.t("ui_button_start_timer")
	elif networked:
		timer_start_button.text = Loc.t("ui_button_start_timer")
	prev_phase_button.text = Loc.t("ui_button_prev_phase")
	next_phase_button.text = Loc.t("ui_button_next_phase")
	phase_counter_label.text = "%d / %d" % [current_phase_index + 1, Round3Data.phases.size()]

	if Round3Data.phases.is_empty():
		return
	var phase: Dictionary = Round3Data.phases[current_phase_index]
	if phase.phase_type == "text":
		phase_title_label.text = Loc.t(phase.title_key)
		phase_body_label.text = Loc.t(phase.body_key)
	elif phase.phase_type == "topics":
		topics_title_label.text = Loc.t(phase.title_key)
		for i in range(topic_list.get_child_count()):
			topic_list.get_child(i).text = "%s %s" % [Round3Data.topics[i].icon, Loc.t(Round3Data.topics[i].name_key)]
		if selected_topic_index >= 0:
			topic_framing_label.text = Loc.t(Round3Data.topics[selected_topic_index].framing_key)
	elif phase.phase_type == "debrief":
		debrief_title_label.text = Loc.t(phase.title_key)
		for child in debrief_list.get_children():
			child.text = "• " + Loc.t(child.get_meta("key"))
