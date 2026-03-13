extends Node2D

const PlayerView = preload("res://scripts/world/Player.gd")
const InteractableView = preload("res://scripts/world/Interactable.gd")
const NPCView = preload("res://scripts/world/NPCView.gd")
const WorldBackdrop = preload("res://scripts/world/WorldBackdrop.gd")
const WorldAmbient = preload("res://scripts/world/WorldAmbient.gd")
const WorldForeground = preload("res://scripts/world/WorldForeground.gd")
const WorldStructureOverlay = preload("res://scripts/world/WorldStructureOverlay.gd")
const HouseInteriorView = preload("res://scripts/world/HouseInterior.gd")
const MiniMapView = preload("res://scripts/world/MiniMap.gd")
const WorldLayout = preload("res://scripts/world/WorldLayout.gd")

const WORLD_RECT := WorldLayout.WORLD_RECT
const WORLD_VISUAL_SCALE := 2.0
const PLAYER_SPEED := 260.0
const AI_PULSE_SECONDS := 60.0
const VISUAL_DAY_CYCLE_SECONDS := 600.0
const VISUAL_START_CLOCK_MINUTES := 8 * 60
const MUSIC_LIBRARY_PATH := "res://yinyue"
const CAMERA_WORLD_ZOOM := Vector2(1.08, 1.08)
const CAMERA_LOOKAHEAD_DISTANCE := 76.0
const CAMERA_LOOKAHEAD_LERP := 7.5
const DISTRICT_RECTS := WorldLayout.DISTRICT_RECTS
const NEWS_TICKER_SECONDS := 5.5
const NPC_AUTO_TALK_SECONDS := 12.0
const NPC_AUTO_TALK_RADIUS := 112.0
const DIRECT_TALK_RADIUS := 88.0
const HOUSE_ENTRY_RADIUS := 64.0
const BACKEND_RETRY_MSEC := 5000
const BACKEND_HEALTHCHECK_MSEC := 1600
const PLAYER_TALK_TIMEOUT_MSEC := 18000
const PLAYER_TALK_RETRY_LIMIT := 0

var player := PlayerView.new()
var world_tint := CanvasModulate.new()
var backdrop := WorldBackdrop.new()
var ambient := WorldAmbient.new()
var foreground := WorldForeground.new()
var top_overlay := WorldStructureOverlay.new()
var world_actor_layer := Node2D.new()
var house_interior := HouseInteriorView.new()
var world_camera := Camera2D.new()
var music_player := AudioStreamPlayer.new()
var npc_layer := Node2D.new()
var interactable_layer := Node2D.new()
var ui_layer := CanvasLayer.new()
var ui_root := Control.new()
var poll_timer := Timer.new()
var conversation_timer := Timer.new()
var ai_pulse_timer := Timer.new()
var toast_timer := Timer.new()

var npc_views: Dictionary = {}
var interactables: Array = []
var current_interactable: InteractableView = null
var show_hearing_debug := false
var inspection_mode := false
var ledger_ui_visible := false
var interior_mode := false
var toast_queue: Array[String] = []
var district_labels: Dictionary = {}
var district_chips: Dictionary = {}
var world_overlay_nodes: Array[CanvasItem] = []
var optional_ui_nodes: Array[CanvasItem] = []
var compact_ui_nodes: Array[CanvasItem] = []
var current_house_data: Dictionary = {}
var last_news_titles: Array[String] = []
var pending_player_reaction: Dictionary = {}
var last_move_input := Vector2.ZERO
var last_auto_enter_msec := 0
var camera_focus_offset := Vector2.ZERO
var backend_autostart_attempted := false
var backend_process_id := -1
var backend_service_ready := false
var backend_health_pending := false
var backend_world_state_pending := false
var backend_last_start_msec := -60000
var backend_last_healthcheck_msec := -60000
var backend_error_streak := 0
var pending_dialogue_request: Dictionary = {}
var music_rng := RandomNumberGenerator.new()
var music_library: Array[String] = []
var current_music_path := ""
var last_snapshot: Dictionary = {}
var visual_cycle_seconds := 0.0
var visual_clock_minutes := VISUAL_START_CLOCK_MINUTES
var visual_day_offset := 0
var visual_time_synced := false
var last_visual_clock_label := ""
var last_visual_period := ""
var active_dialogue_context: Dictionary = {}
var news_ticker_items: Array[String] = []
var news_ticker_index := 0
var news_ticker_elapsed := 0.0
var npc_auto_talk_elapsed := 0.0
var npc_last_auto_talker := ""

var minimap := MiniMapView.new()
var overview_label := Label.new()
var district_bar := HBoxContainer.new()
var goods_label := RichTextLabel.new()
var stocks_label := RichTextLabel.new()
var news_label := RichTextLabel.new()
var families_label := RichTextLabel.new()
var macro_label := RichTextLabel.new()
var scene_note_label := RichTextLabel.new()
var highlights_label := RichTextLabel.new()
var tasks_label := RichTextLabel.new()
var status_label := Label.new()
var hint_label := Label.new()
var subtitle_label := Label.new()
var toast_label := Label.new()
var guide_label := RichTextLabel.new()
var action_panel := VBoxContainer.new()
var modal_overlay := ColorRect.new()
var modal_title := Label.new()
var modal_body := RichTextLabel.new()
var modal_body_scroll := ScrollContainer.new()
var modal_card := PanelContainer.new()
var modal_input := LineEdit.new()
var modal_send_button := Button.new()
var modal_hint_label := Label.new()
var modal_trade_title := Label.new()
var modal_trade_label := RichTextLabel.new()
var modal_trade_scroll := ScrollContainer.new()
var modal_trade_buttons := FlowContainer.new()
var modal_is_conversation := false
var compact_hud_label := RichTextLabel.new()
var market_flash_label := RichTextLabel.new()
var news_ticker_label := RichTextLabel.new()
var interaction_badge_label := Label.new()
var inspect_badge := Label.new()
var hud_badge := Label.new()
var exchange_terminal_panel := PanelContainer.new()
var exchange_terminal_title := Label.new()
var exchange_terminal_summary := RichTextLabel.new()
var exchange_terminal_tape := RichTextLabel.new()
var exchange_terminal_actions := VBoxContainer.new()
var exchange_terminal_nodes: Array[CanvasItem] = []
var minimap_panel_node: CanvasItem
var subtitle_panel_node: CanvasItem
var toast_tween: Tween
var modal_tween: Tween
var last_viewport_size := Vector2.ZERO


func _ready() -> void:
	Engine.max_fps = 60
	add_child(world_tint)
	add_child(backdrop)
	add_child(world_actor_layer)
	world_actor_layer.y_sort_enabled = true
	world_actor_layer.add_child(interactable_layer)
	world_actor_layer.add_child(npc_layer)
	world_actor_layer.add_child(player)
	add_child(top_overlay)
	add_child(house_interior)
	add_child(world_camera)
	add_child(music_player)
	add_child(ui_layer)
	interactable_layer.y_sort_enabled = true
	npc_layer.y_sort_enabled = true
	interactable_layer.z_index = -2
	ui_layer.add_child(ui_root)
	backdrop.scale = Vector2.ONE * WORLD_VISUAL_SCALE
	top_overlay.scale = Vector2.ONE * WORLD_VISUAL_SCALE
	player.position = _to_world_position(WorldLayout.snap_to_walkable(WorldLayout.PLAYER_START))
	world_camera.enabled = true
	world_camera.position_smoothing_enabled = true
	world_camera.position_smoothing_speed = 7.5
	world_camera.zoom = CAMERA_WORLD_ZOOM
	world_camera.position = player.position
	var scaled_world_size := WORLD_RECT.size * WORLD_VISUAL_SCALE
	world_camera.limit_left = 0
	world_camera.limit_top = 0
	world_camera.limit_right = int(scaled_world_size.x)
	world_camera.limit_bottom = int(scaled_world_size.y)
	music_player.bus = &"Master"
	music_player.volume_db = -12.0
	music_player.finished.connect(_on_music_finished)
	music_rng.randomize()
	_scan_music_library()
	_build_interactables()
	_build_ui()
	_build_world_labels()
	house_interior.set_active(false)

	ApiClient.response_received.connect(_on_api_response)
	ApiClient.request_failed.connect(_handle_api_error_v3)
	GameState.snapshot_updated.connect(_on_snapshot_updated)
	GameState.toast_added.connect(_enqueue_toast)
	UiRouter.modal_requested.connect(_on_modal_requested)
	UiRouter.guide_updated.connect(_on_guide_updated)

	poll_timer.wait_time = 1.6
	poll_timer.timeout.connect(_poll_world_state)
	add_child(poll_timer)
	poll_timer.start()

	conversation_timer.wait_time = 4.5
	conversation_timer.timeout.connect(_trigger_proximity_conversation)
	add_child(conversation_timer)
	conversation_timer.start()

	ai_pulse_timer.wait_time = AI_PULSE_SECONDS
	ai_pulse_timer.timeout.connect(_on_ai_pulse_timer_timeout)
	add_child(ai_pulse_timer)
	ai_pulse_timer.start()

	toast_timer.wait_time = 3.5
	toast_timer.one_shot = true
	toast_timer.timeout.connect(_show_next_toast)
	add_child(toast_timer)

	_probe_backend_health()


func _process(delta: float) -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size != last_viewport_size:
		_layout_exchange_terminal_panel()
	_advance_visual_clock(delta)
	_advance_news_ticker(delta)
	_maintain_pending_dialogue_request()
	if interior_mode:
		house_interior.tick(delta)
		current_interactable = house_interior.get_current_interactable()
		hint_label.text = house_interior.get_hint_text()
	else:
		_move_player(delta)
		_update_world_camera(delta)
		_update_current_interactable()
		_update_npc_attention()
		_maybe_trigger_proactive_npc_talk(delta)
	_refresh_interaction_badge()
	_update_subtitles()
	if not interior_mode:
		_update_minimap()
	if Input.is_action_just_pressed("enter_house_hotkey"):
		_trigger_house_entry_hotkey()
	if Input.is_action_just_pressed("interact"):
		_trigger_primary_interaction()
	if Input.is_action_just_pressed("debug_hearing"):
		show_hearing_debug = not show_hearing_debug
		_refresh_npcs()
	if Input.is_action_just_pressed("toggle_ledger_ui"):
		_set_ledger_ui_visible(not ledger_ui_visible)
	if Input.is_action_just_pressed("toggle_inspect_view"):
		_set_inspection_mode(not inspection_mode)
	if Input.is_action_just_pressed("ui_cancel"):
		_handle_cancel_input()


func _exit_tree() -> void:
	for timer in [poll_timer, conversation_timer, ai_pulse_timer, toast_timer]:
		if is_instance_valid(timer):
			timer.stop()
	if is_instance_valid(toast_tween):
		toast_tween.kill()
		toast_tween = null
	if is_instance_valid(modal_tween):
		modal_tween.kill()
		modal_tween = null
	if is_instance_valid(music_player):
		music_player.stop()
		music_player.stream = null


func _maintain_pending_dialogue_request() -> void:
	if true:
		if pending_dialogue_request.is_empty():
			return
		if not modal_overlay.visible:
			pending_dialogue_request = {}
			return
		var started_msec := int(pending_dialogue_request.get("started_msec", 0))
		if started_msec <= 0:
			pending_dialogue_request["started_msec"] = Time.get_ticks_msec()
			return
		var now := Time.get_ticks_msec()
		if now - started_msec < PLAYER_TALK_TIMEOUT_MSEC:
			status_label.text = "对方正在组织说法……"
			return
		modal_send_button.disabled = false
		pending_dialogue_request = {}
		status_label.text = "这轮追问超时了，你可以直接再发一次。"
		return
	if pending_dialogue_request.is_empty():
		return
	if not modal_overlay.visible:
		pending_dialogue_request = {}
		return
	var started_msec := int(pending_dialogue_request.get("started_msec", 0))
	if started_msec <= 0:
		pending_dialogue_request["started_msec"] = Time.get_ticks_msec()
		return
	var now := Time.get_ticks_msec()
	if now - started_msec < PLAYER_TALK_TIMEOUT_MSEC:
		status_label.text = "对方正在整理说法……"
		return
	modal_send_button.disabled = false
	pending_dialogue_request = {}
	status_label.text = "这轮追问超时了，你可以直接再发一次。"


func _retry_pending_dialogue_request(now: int = -1) -> void:
	if pending_dialogue_request.is_empty():
		return
	var retry_started := Time.get_ticks_msec() if now < 0 else now
	pending_dialogue_request["retry_count"] = int(pending_dialogue_request.get("retry_count", 0)) + 1
	pending_dialogue_request["started_msec"] = retry_started
	var live_scene := _build_scene_observation_payload(false)
	ApiClient.post_json("/npc/player_talk", {
		"npc_id": str(pending_dialogue_request.get("npc_id", "")),
		"district": str(pending_dialogue_request.get("district", _current_district_for_position(player.position))),
		"topic_id": str(pending_dialogue_request.get("topic_id", "")),
		"approach": str(pending_dialogue_request.get("approach", "cautious")),
		"intent": str(pending_dialogue_request.get("intent", "继续追问")),
		"player_input": str(pending_dialogue_request.get("player_input", "")),
		"player_position": live_scene.get("player_position", {}),
		"screenshot_b64": "",
		"scene_context": live_scene.get("scene_context", {})
	}, "player_talk")
	status_label.text = "对方还在组织话头，正在重试。"


func _build_world_labels() -> void:
	for district_name in DISTRICT_RECTS.keys():
		var title := Label.new()
		title.text = district_name
		title.position = _to_world_position(WorldLayout.label_position_for_district(district_name))
		title.add_theme_font_size_override("font_size", 30)
		title.add_theme_color_override("font_color", Color("f1dec0"))
		ui_root.add_child(title)
		world_overlay_nodes.append(title)

		var badge := Label.new()
		badge.text = "状态 normal · 人流 0"
		badge.position = _to_world_position(WorldLayout.label_position_for_district(district_name) + Vector2(4, 36))
		badge.add_theme_font_size_override("font_size", 15)
		badge.add_theme_color_override("font_color", Color("ead1a4"))
		ui_root.add_child(badge)
		world_overlay_nodes.append(badge)
		district_labels[district_name] = badge


func _build_interactables() -> void:
	var items := WorldLayout.interactable_rows()
	for item in items:
		var node := InteractableView.new()
		node.configure(item)
		var layout_position := Vector2(float(item.get("x", 0.0)), float(item.get("y", 0.0)))
		if str(item.get("kind", "")) != "house" and not WorldLayout.is_walkable_point(layout_position):
			var snapped_position := WorldLayout.snap_to_walkable(layout_position)
			if layout_position.distance_to(snapped_position) <= 36.0:
				layout_position = snapped_position
		node.position = _to_world_position(layout_position)
		node.scale = Vector2.ONE * 1.08
		interactable_layer.add_child(node)
		interactables.append(node)


func _build_ui() -> void:
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)

	var compact_margin := _make_overlay_card(Rect2(18, 18, 466, 92))
	compact_hud_label.bbcode_enabled = true
	compact_hud_label.fit_content = true
	compact_hud_label.scroll_active = false
	compact_hud_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	compact_hud_label.add_theme_color_override("default_color", Color("f5e8c6"))
	compact_margin.add_child(compact_hud_label)

	var market_margin := _make_overlay_card(Rect2(1096, 18, 486, 92))
	market_flash_label.bbcode_enabled = true
	market_flash_label.fit_content = true
	market_flash_label.scroll_active = false
	market_flash_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	market_flash_label.add_theme_color_override("default_color", Color("f5e8c6"))
	market_margin.add_child(market_flash_label)

	var ticker_margin := _make_overlay_card(Rect2(282, 742, 888, 44))
	news_ticker_label.bbcode_enabled = true
	news_ticker_label.fit_content = false
	news_ticker_label.scroll_active = false
	news_ticker_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	news_ticker_label.custom_minimum_size = Vector2(860, 30)
	news_ticker_label.add_theme_color_override("default_color", Color("f3e7c7"))
	ticker_margin.add_child(news_ticker_label)
	
	var exchange_style := StyleBoxFlat.new()
	exchange_style.bg_color = Color(0.09, 0.12, 0.16, 0.9)
	exchange_style.border_color = Color("d8b982")
	exchange_style.border_width_left = 2
	exchange_style.border_width_top = 2
	exchange_style.border_width_right = 2
	exchange_style.border_width_bottom = 2
	exchange_style.corner_radius_top_left = 10
	exchange_style.corner_radius_top_right = 10
	exchange_style.corner_radius_bottom_left = 10
	exchange_style.corner_radius_bottom_right = 10
	exchange_terminal_panel.position = Vector2(1060, 122)
	exchange_terminal_panel.size = Vector2(510, 446)
	exchange_terminal_panel.visible = false
	exchange_terminal_panel.add_theme_stylebox_override("panel", exchange_style)
	ui_root.add_child(exchange_terminal_panel)
	exchange_terminal_nodes.append(exchange_terminal_panel)

	var exchange_margin := MarginContainer.new()
	exchange_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	exchange_margin.add_theme_constant_override("margin_left", 14)
	exchange_margin.add_theme_constant_override("margin_top", 12)
	exchange_margin.add_theme_constant_override("margin_right", 14)
	exchange_margin.add_theme_constant_override("margin_bottom", 12)
	exchange_terminal_panel.add_child(exchange_margin)

	var exchange_box := VBoxContainer.new()
	exchange_box.add_theme_constant_override("separation", 8)
	exchange_margin.add_child(exchange_box)

	exchange_terminal_title.text = "证券交易终端"
	exchange_terminal_title.add_theme_font_size_override("font_size", 24)
	exchange_terminal_title.add_theme_color_override("font_color", Color("f4dfb7"))
	exchange_box.add_child(exchange_terminal_title)

	_setup_rich_text(exchange_terminal_summary, false)
	exchange_terminal_summary.custom_minimum_size = Vector2(0, 164)
	exchange_terminal_summary.add_theme_color_override("default_color", Color("e9dcc0"))
	exchange_box.add_child(exchange_terminal_summary)

	_setup_rich_text(exchange_terminal_tape, false)
	exchange_terminal_tape.custom_minimum_size = Vector2(0, 82)
	exchange_terminal_tape.add_theme_color_override("default_color", Color("d4c29c"))
	exchange_box.add_child(exchange_terminal_tape)

	exchange_terminal_actions.add_theme_constant_override("separation", 6)
	exchange_box.add_child(exchange_terminal_actions)
	_layout_exchange_terminal_panel()

	var overview_panel := _make_panel(Rect2(18, 18, 448, 148), "乌龟账本")
	overview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overview_label.add_theme_font_size_override("font_size", 18)
	overview_label.add_theme_color_override("font_color", Color("2d2014"))
	overview_panel.body.add_child(overview_label)
	_register_optional_ui(overview_panel.panel)

	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color("5f4a30"))
	overview_panel.body.add_child(status_label)

	district_bar.add_theme_constant_override("separation", 8)
	overview_panel.body.add_child(district_bar)
	for district_name in DISTRICT_RECTS.keys():
		var chip := Button.new()
		chip.text = district_name
		chip.disabled = true
		chip.add_theme_font_size_override("font_size", 13)
		chip.add_theme_color_override("font_color", Color("f6e7c5"))
		chip.add_theme_color_override("font_disabled_color", Color("f6e7c5"))
		chip.add_theme_stylebox_override("normal", _make_chip_style(Color("5e4633")))
		chip.add_theme_stylebox_override("disabled", _make_chip_style(Color("5e4633")))
		district_bar.add_child(chip)
		district_chips[district_name] = chip

	var goods_panel := _make_panel(Rect2(18, 182, 330, 252), "货摊账页")
	_setup_rich_text(goods_label, false)
	goods_panel.body.add_child(goods_label)
	_register_optional_ui(goods_panel.panel)

	var stocks_panel := _make_panel(Rect2(362, 182, 330, 252), "股票账页")
	_setup_rich_text(stocks_label, false)
	stocks_panel.body.add_child(stocks_label)
	_register_optional_ui(stocks_panel.panel)

	var macro_panel := _make_panel(Rect2(708, 18, 462, 170), "宏观风向")
	_setup_rich_text(macro_label, false)
	macro_panel.body.add_child(macro_label)
	_setup_rich_text(scene_note_label, false)
	scene_note_label.custom_minimum_size = Vector2(0, 40)
	macro_panel.body.add_child(scene_note_label)
	_register_optional_ui(macro_panel.panel)

	var highlights_panel := _make_panel(Rect2(708, 204, 462, 264), "关键耳语")
	_setup_rich_text(highlights_label, true)
	highlights_panel.body.add_child(highlights_label)
	_register_optional_ui(highlights_panel.panel)

	var tasks_panel := _make_panel(Rect2(708, 484, 462, 346), "关系与告示")
	_setup_rich_text(tasks_label, true)
	tasks_panel.body.add_child(tasks_label)
	_register_optional_ui(tasks_panel.panel)

	var news_panel := _make_panel(Rect2(1190, 18, 392, 418), "新闻与广播")
	_setup_rich_text(news_label, true)
	news_panel.body.add_child(news_label)
	_register_optional_ui(news_panel.panel)

	var family_panel := _make_panel(Rect2(1190, 452, 392, 378), "家族简报")
	_setup_rich_text(families_label, true)
	family_panel.body.add_child(families_label)
	_register_optional_ui(family_panel.panel)

	var action_panel_shell := _make_panel(Rect2(18, 450, 674, 380), "交互与演示控制")
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", 17)
	hint_label.add_theme_color_override("font_color", Color("2d2014"))
	action_panel_shell.body.add_child(hint_label)

	guide_label.bbcode_enabled = true
	guide_label.fit_content = true
	guide_label.scroll_active = false
	guide_label.add_theme_color_override("default_color", Color("2d2014"))
	action_panel_shell.body.add_child(guide_label)

	var action_scroll := ScrollContainer.new()
	action_scroll.custom_minimum_size = Vector2(0, 214)
	action_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_panel_shell.body.add_child(action_scroll)

	action_panel.add_theme_constant_override("separation", 6)
	action_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_scroll.add_child(action_panel)
	_register_optional_ui(action_panel_shell.panel)

	var minimap_panel := _make_panel(Rect2(18, 844, 248, 118), "城区简图")
	minimap.custom_minimum_size = Vector2(208, 74)
	minimap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	minimap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	minimap.configure(Rect2(Vector2.ZERO, WORLD_RECT.size * WORLD_VISUAL_SCALE), _scaled_district_rects())
	minimap_panel.body.add_child(minimap)
	_register_optional_ui(minimap_panel.panel)
	minimap_panel_node = minimap_panel.panel

	var subtitle_panel := _make_panel(Rect2(282, 844, 888, 118), "街头耳语")
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_font_size_override("font_size", 19)
	subtitle_label.add_theme_color_override("font_color", Color("2d2014"))
	subtitle_panel.body.add_child(subtitle_label)
	subtitle_panel_node = subtitle_panel.panel

	var interaction_margin := _make_overlay_card(Rect2(282, 792, 888, 44))
	interaction_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interaction_badge_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	interaction_badge_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	interaction_badge_label.add_theme_font_size_override("font_size", 18)
	interaction_badge_label.add_theme_color_override("font_color", Color("f5e8c6"))
	interaction_margin.add_child(interaction_badge_label)

	inspect_badge.position = Vector2(1290, 842)
	inspect_badge.size = Vector2(270, 42)
	inspect_badge.text = "查看模式已开启 [Tab]"
	inspect_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inspect_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inspect_badge.visible = false
	inspect_badge.add_theme_font_size_override("font_size", 18)
	inspect_badge.add_theme_color_override("font_color", Color("f7e5c0"))
	ui_root.add_child(inspect_badge)

	hud_badge.position = Vector2(1210, 24)
	hud_badge.size = Vector2(350, 50)
	hud_badge.text = "[H] 展开账本  [Tab] 查看场景"
	hud_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud_badge.add_theme_font_size_override("font_size", 17)
	hud_badge.add_theme_color_override("font_color", Color("f2dfb8"))
	ui_root.add_child(hud_badge)

	toast_label.position = Vector2(636, 24)
	toast_label.size = Vector2(340, 60)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 22)
	toast_label.add_theme_color_override("font_color", Color("fff0ce"))
	ui_root.add_child(toast_label)

	modal_overlay.color = Color(0.07, 0.05, 0.03, 0.82)
	modal_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_overlay.visible = false
	ui_root.add_child(modal_overlay)

	modal_card.position = Vector2(366, 208)
	modal_card.size = Vector2(868, 436)
	modal_card.pivot_offset = modal_card.size / 2.0
	var modal_style := StyleBoxFlat.new()
	modal_style.bg_color = Color("ead4a9")
	modal_style.border_color = Color("4d331f")
	modal_style.border_width_left = 6
	modal_style.border_width_top = 6
	modal_style.border_width_right = 6
	modal_style.border_width_bottom = 6
	modal_style.corner_radius_top_left = 12
	modal_style.corner_radius_top_right = 12
	modal_style.corner_radius_bottom_left = 12
	modal_style.corner_radius_bottom_right = 12
	modal_card.add_theme_stylebox_override("panel", modal_style)
	modal_overlay.add_child(modal_card)

	var modal_margin := MarginContainer.new()
	modal_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_margin.add_theme_constant_override("margin_left", 24)
	modal_margin.add_theme_constant_override("margin_top", 24)
	modal_margin.add_theme_constant_override("margin_right", 24)
	modal_margin.add_theme_constant_override("margin_bottom", 24)
	modal_card.add_child(modal_margin)

	var modal_box := VBoxContainer.new()
	modal_box.add_theme_constant_override("separation", 12)
	modal_margin.add_child(modal_box)

	modal_title.add_theme_font_size_override("font_size", 32)
	modal_title.add_theme_color_override("font_color", Color("3a2819"))
	modal_box.add_child(modal_title)

	modal_body.bbcode_enabled = true
	modal_body.fit_content = true
	modal_body.scroll_active = false
	modal_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_body.add_theme_color_override("default_color", Color("2d2014"))
	modal_body_scroll.custom_minimum_size = Vector2(0, 250)
	modal_body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	modal_body_scroll.add_child(modal_body)
	modal_box.add_child(modal_body_scroll)

	modal_hint_label.text = "直接输入一句话发给对面的角色，由大模型实时生成回应。"
	modal_hint_label.add_theme_font_size_override("font_size", 16)
	modal_hint_label.add_theme_color_override("font_color", Color("6a5137"))
	modal_box.add_child(modal_hint_label)

	modal_trade_title.text = "当面交易"
	modal_trade_title.add_theme_font_size_override("font_size", 22)
	modal_trade_title.add_theme_color_override("font_color", Color("5c3920"))
	modal_trade_title.visible = false
	modal_box.add_child(modal_trade_title)

	modal_trade_label.bbcode_enabled = true
	modal_trade_label.fit_content = true
	modal_trade_label.scroll_active = false
	modal_trade_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_trade_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_trade_label.add_theme_color_override("default_color", Color("4b3520"))
	modal_trade_label.visible = false
	modal_trade_scroll.custom_minimum_size = Vector2(0, 118)
	modal_trade_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_trade_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	modal_trade_scroll.visible = false
	modal_trade_scroll.add_child(modal_trade_label)
	modal_box.add_child(modal_trade_scroll)

	modal_trade_buttons.add_theme_constant_override("h_separation", 8)
	modal_trade_buttons.add_theme_constant_override("v_separation", 8)
	modal_trade_buttons.visible = false
	modal_box.add_child(modal_trade_buttons)

	var input_row := HBoxContainer.new()
	input_row.add_theme_constant_override("separation", 10)
	modal_box.add_child(input_row)

	modal_input.placeholder_text = "输入你想对 TA 说的话…"
	modal_input.custom_minimum_size = Vector2(650, 42)
	modal_input.visible = false
	modal_input.text_submitted.connect(func(_text: String) -> void:
		_submit_modal_player_talk()
	)
	input_row.add_child(modal_input)

	modal_send_button.text = "发送追问"
	modal_send_button.visible = false
	_style_button(modal_send_button, Color("2f6f4f"), Color("3f8a60"), Color("244f3a"))
	modal_send_button.pressed.connect(_submit_modal_player_talk)
	input_row.add_child(modal_send_button)
	get_viewport().size_changed.connect(_layout_modal_card)
	_layout_modal_card()

	var dismiss := Button.new()
	dismiss.text = "收起告示"
	_style_button(dismiss, Color("6c4a2a"), Color("8a6037"), Color("4f3520"))
	dismiss.pressed.connect(func() -> void:
		if is_instance_valid(modal_tween):
			modal_tween.kill()
		modal_tween = create_tween()
		modal_tween.set_parallel(true)
		modal_tween.tween_property(modal_overlay, "modulate", Color(1, 1, 1, 0), 0.14)
		modal_tween.tween_property(modal_card, "scale", Vector2(0.96, 0.96), 0.14)
		modal_tween.finished.connect(func() -> void:
			modal_overlay.visible = false
		)
	)
	modal_box.add_child(dismiss)
	_apply_visibility_modes()
	_update_exchange_terminal(last_snapshot)


func _layout_modal_card() -> void:
	var viewport_size := get_viewport_rect().size
	var card_width := clampf(viewport_size.x - 140.0, 760.0, 1040.0)
	var card_height := clampf(viewport_size.y - 120.0, 430.0, 760.0)
	modal_card.size = Vector2(card_width, card_height)
	modal_card.position = (viewport_size - modal_card.size) * 0.5
	modal_card.pivot_offset = modal_card.size * 0.5
	if modal_is_conversation:
		modal_body_scroll.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		modal_body_scroll.custom_minimum_size = Vector2(0, clampf(card_height * 0.18, 92.0, 150.0))
		modal_trade_scroll.custom_minimum_size = Vector2(0, clampf(card_height * 0.26, 130.0, 210.0))
	else:
		modal_body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		modal_body_scroll.custom_minimum_size = Vector2(0, max(190.0, card_height * 0.34))
		modal_trade_scroll.custom_minimum_size = Vector2(0, max(96.0, min(164.0, card_height * 0.2)))
	modal_input.custom_minimum_size = Vector2(max(360.0, card_width - 210.0), 42)


func _layout_exchange_terminal_panel() -> void:
	if not is_instance_valid(exchange_terminal_panel):
		return
	var viewport_size := get_viewport_rect().size
	last_viewport_size = viewport_size
	var panel_width := clampf(viewport_size.x * 0.32, 360.0, 510.0)
	var panel_height := clampf(viewport_size.y - 190.0, 330.0, 446.0)
	var panel_x := maxf(16.0, viewport_size.x - panel_width - 24.0)
	var panel_y := clampf(122.0, 16.0, maxf(16.0, viewport_size.y - panel_height - 24.0))
	exchange_terminal_panel.position = Vector2(panel_x, panel_y)
	exchange_terminal_panel.size = Vector2(panel_width, panel_height)
	exchange_terminal_summary.custom_minimum_size = Vector2(0, clampf(panel_height * 0.37, 128.0, 164.0))
	exchange_terminal_tape.custom_minimum_size = Vector2(0, clampf(panel_height * 0.2, 72.0, 96.0))


func _make_panel(rect: Rect2, title: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.position = rect.position
	panel.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = Color("e7d0a1")
	style.border_color = Color("4d331f")
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)
	ui_root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	margin.add_child(body)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	body.add_child(header_row)

	var seal := ColorRect.new()
	seal.color = Color("8f2f33")
	seal.custom_minimum_size = Vector2(12, 12)
	header_row.add_child(seal)

	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", Color("3a2819"))
	header_row.add_child(header)

	return {"panel": panel, "body": body}


func _make_overlay_card(rect: Rect2) -> MarginContainer:
	var panel := PanelContainer.new()
	panel.position = rect.position
	panel.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.1, 0.07, 0.84)
	style.border_color = Color("d7bc8c")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	ui_root.add_child(panel)
	compact_ui_nodes.append(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	return margin


func _setup_rich_text(node: RichTextLabel, scrolling: bool) -> void:
	node.bbcode_enabled = true
	node.fit_content = true
	node.scroll_active = scrolling
	node.add_theme_color_override("default_color", Color("2d2014"))


func _register_optional_ui(node: CanvasItem) -> void:
	optional_ui_nodes.append(node)


func _update_compact_hud_legacy(snapshot: Dictionary, district_name: String) -> void:
	var player_data: Dictionary = snapshot.get("player", {})
	var quick: Dictionary = snapshot.get("quick_hud", {})
	var metrics: Dictionary = snapshot.get("demo_metrics", {})
	var visual_summary := _compose_visual_macro_summary(snapshot.get("macro_summary", {}))
	var subregion_name := _current_subregion_for_position(player.position if not interior_mode else house_interior.get_player_position())
	var area_label := district_name
	if not subregion_name.is_empty():
		area_label = "%s · %s" % [district_name, subregion_name]
	var social_prompt := str(quick.get("social_prompt", ""))
	var institution_flash := str(quick.get("institution_flash", ""))
	var ai_focus := _sanitize_visible_text(str(quick.get("ai_focus", "")), "")
	var market_note := _sanitize_visible_text(str(quick.get("market_note", "")), "")
	var market_flash := _sanitize_visible_text(str(quick.get("market_flash", "")), "市场还安静")
	var objective_line := str(quick.get("objective", "先在街上看一圈。"))
	if not social_prompt.is_empty():
		objective_line += "\n街上最值得问的是：%s" % social_prompt
	if not institution_flash.is_empty():
		objective_line += "\n机构动作：%s" % institution_flash
	if not ai_focus.is_empty():
		objective_line += "\nAI 脉冲：%s" % ai_focus
	compact_hud_label.text = "[b]第 %s 天 %s[/b]  %s 铜币  ·  %s\n%s\n[color=#d4b98b]劳动:%s  情报:%s  股票:%s[/color]" % [
		int(snapshot.get("day", 1)) + visual_day_offset,
		visual_summary.get("clock_label", "08:00"),
		player_data.get("cash", 0),
		area_label,
		objective_line,
		metrics.get("work_actions", 0),
		metrics.get("intel_actions", 0),
		metrics.get("stock_trades", 0)
	]
	var secondary_line := _sanitize_visible_text(str(quick.get("latest_news_title", "")), "")
	if secondary_line.is_empty():
		secondary_line = _sanitize_visible_text(str(quick.get("latest_rumor", "街上暂时没新风声。")), "街上暂时没新风声。")
	if not market_note.is_empty():
		secondary_line += "\n%s" % market_note
	market_flash_label.text = "[b]盘口[/b] %s\n%s" % [
		market_flash,
		secondary_line
	]


func _compact_stock_board(snapshot: Dictionary) -> String:
	var stocks: Array = snapshot.get("stocks", [])
	var tape: Array = snapshot.get("stock_trade_tape", [])
	if stocks.is_empty():
		return ""
	var stock_lines: Array[String] = []
	for item in stocks.slice(0, min(3, stocks.size())):
		var change_pct := float(item.get("change_pct", 0.0)) * 100.0
		stock_lines.append("%s %s (%+.2f%%)" % [
			str(item.get("name", "")),
			str(item.get("current_price", 0)),
			change_pct
		])
	var result := "[b]三股[/b] %s" % " / ".join(stock_lines)
	if not tape.is_empty():
		result += "\n[b]最近成交[/b] %s" % _sanitize_visible_text(str(tape[0].get("anonymous_label", "")), "还没有人下单")
	return result


func _update_compact_hud(snapshot: Dictionary, district_name: String) -> void:
	var player_data: Dictionary = snapshot.get("player", {})
	var quick: Dictionary = snapshot.get("quick_hud", {})
	var metrics: Dictionary = snapshot.get("demo_metrics", {})
	var visual_summary := _compose_visual_macro_summary(snapshot.get("macro_summary", {}))
	var subregion_name := _current_subregion_for_position(player.position if not interior_mode else house_interior.get_player_position())
	var area_label := district_name
	if not subregion_name.is_empty():
		area_label = "%s · %s" % [district_name, subregion_name]
	var social_prompt := _sanitize_visible_text(str(quick.get("social_prompt", "")), "")
	var institution_flash := _sanitize_visible_text(str(quick.get("institution_flash", "")), "")
	var ai_focus := _sanitize_visible_text(str(quick.get("ai_focus", "")), "")
	var market_note := _sanitize_visible_text(str(quick.get("market_note", "")), "")
	var market_flash := _sanitize_visible_text(str(quick.get("market_flash", "")), "市场还算平静")
	var objective_line := str(quick.get("objective", "先在街上看一圈，摸清地形和价格。"))
	if not social_prompt.is_empty():
		objective_line += "\n街上最值得问的是：%s" % social_prompt
	if not institution_flash.is_empty():
		objective_line += "\n机构动作：%s" % institution_flash
	if not ai_focus.is_empty():
		objective_line += "\nAI 脉冲：%s" % ai_focus
	compact_hud_label.text = "[b]第 %s 天 %s[/b]  %s 铜币 · %s\n%s\n[color=#d4b98b]劳动:%s  情报:%s  股票:%s[/color]" % [
		int(snapshot.get("day", 1)) + visual_day_offset,
		visual_summary.get("clock_label", "08:00"),
		player_data.get("cash", 0),
		area_label,
		objective_line,
		metrics.get("work_actions", 0),
		metrics.get("intel_actions", 0),
		metrics.get("stock_trades", 0)
	]
	var secondary_line := _sanitize_visible_text(str(quick.get("latest_news_title", "")), "")
	if secondary_line.is_empty():
		secondary_line = _sanitize_visible_text(str(quick.get("latest_rumor", "街上暂时没新风声。")), "街上暂时没新风声。")
	if not market_note.is_empty():
		secondary_line += "\n%s" % market_note
	var stock_board := _compact_stock_board(snapshot)
	if not stock_board.is_empty():
		secondary_line += "\n%s" % stock_board
	market_flash_label.text = "[b]盘口[/b] %s\n%s" % [
		market_flash,
		secondary_line
	]


func _refresh_news_ticker(snapshot: Dictionary) -> void:
	news_ticker_items.clear()
	news_ticker_index = 0
	news_ticker_elapsed = 0.0
	var quick: Dictionary = snapshot.get("quick_hud", {})
	var weather: Dictionary = snapshot.get("weather", {})
	var weather_label := _weather_label_cn(str(weather.get("label", "晴天")))
	var market_flash := _sanitize_visible_text(str(quick.get("market_flash", "")).strip_edges(), "市场还算平静")
	var market_note := _sanitize_visible_text(str(quick.get("market_note", "")).strip_edges(), "")
	var news_rows: Array = snapshot.get("city_news", snapshot.get("global_news", []))
	if not market_flash.is_empty():
		var market_line := "[b]盘口[/b] %s" % market_flash
		if not market_note.is_empty():
			market_line += "  |  %s" % market_note
		news_ticker_items.append(market_line)
	for item in news_rows.slice(0, min(6, news_rows.size())):
		var row: Dictionary = item
		var title := _sanitize_visible_text(str(row.get("title", "")).strip_edges(), "街头广播")
		var body := _sanitize_visible_text(str(row.get("body", "")).strip_edges(), "全城暂时没有新广播。")
		if title.is_empty() and body.is_empty():
			continue
		news_ticker_items.append("[b]%s[/b]  |  %s" % [title, body])
	if news_ticker_items.is_empty():
		news_ticker_items.append("[b]天气[/b] %s  |  全城暂时没有新广播。" % weather_label)
	_apply_news_ticker_line()

func _advance_news_ticker(delta: float) -> void:
	if news_ticker_items.size() <= 1:
		return
	news_ticker_elapsed += delta
	if news_ticker_elapsed < NEWS_TICKER_SECONDS:
		return
	news_ticker_elapsed = 0.0
	news_ticker_index = posmod(news_ticker_index + 1, news_ticker_items.size())
	_apply_news_ticker_line()


func _apply_news_ticker_line() -> void:
	if news_ticker_items.is_empty():
		news_ticker_label.text = "[b]快讯[/b] 全城暂时没有新广播。"
		return
	news_ticker_label.text = "[b]快讯[/b] %s" % news_ticker_items[news_ticker_index]


func _looks_like_english_text(text: String) -> bool:
	var ascii_letters := 0
	var cjk_chars := 0
	for ch in text:
		var code := ch.unicode_at(0)
		if code >= 0x4E00 and code <= 0x9FFF:
			cjk_chars += 1
		elif (code >= 65 and code <= 90) or (code >= 97 and code <= 122):
			ascii_letters += 1
	return ascii_letters >= 12 and ascii_letters > cjk_chars * 2


func _weather_label_cn(raw_label: String) -> String:
	var label := raw_label.strip_edges()
	match label.to_lower():
		"sunny", "clear":
			return "晴天"
		"cloudy":
			return "多云"
		"overcast":
			return "阴天"
		"rain":
			return "雨天"
		"snow":
			return "雪天"
		"dust":
			return "沙尘"
	if label == "鏅村ぉ":
		return "晴天"
	return label if not label.is_empty() else "晴天"


func _sanitize_visible_text(text: String, fallback: String = "") -> String:
	var cleaned := text.strip_edges()
	if cleaned.is_empty():
		return fallback
	cleaned = cleaned.replace("[b]Market[/b]", "[b]盘口[/b]")
	cleaned = cleaned.replace("[b]Ticker[/b]", "[b]快讯[/b]")
	cleaned = cleaned.replace("[b]Weather[/b]", "[b]天气[/b]")
	cleaned = cleaned.replace("No new city bulletin yet.", "全城暂时没有新广播。")
	cleaned = cleaned.replace("on", "开").replace("off", "关")
	if _looks_like_english_text(cleaned):
		return fallback if not fallback.is_empty() else "城里刚有一阵新风声。"
	return cleaned


func _maybe_trigger_proactive_npc_talk(delta: float) -> void:
	if modal_overlay.visible or ledger_ui_visible or inspection_mode or not pending_dialogue_request.is_empty():
		npc_auto_talk_elapsed = 0.0
		return
	npc_auto_talk_elapsed += delta
	if npc_auto_talk_elapsed < NPC_AUTO_TALK_SECONDS:
		return
	if true:
		var nearby_npcs_shell := _get_nearby_npcs(3)
		if nearby_npcs_shell.is_empty():
			return
		for npc_card in nearby_npcs_shell:
			var npc_id := str(npc_card.get("id", ""))
			if npc_id.is_empty() or not npc_views.has(npc_id):
				continue
			if npc_id == npc_last_auto_talker and nearby_npcs_shell.size() > 1:
				continue
			var view: NPCView = npc_views[npc_id]
			var distance := float(npc_card.get("distance", 99999.0))
			if distance > NPC_AUTO_TALK_RADIUS * WORLD_VISUAL_SCALE:
				continue
			var proactive_interest := clampf(float(view.npc_data.get("proactive_interest", 0.32)), 0.12, 0.92)
			if music_rng.randf() > proactive_interest:
				continue
			npc_auto_talk_elapsed = 0.0
			npc_last_auto_talker = npc_id
			view.trigger_social_beat(player.position, true, "speaker", 1.08, 1.0)
			var npc_card_detail := _npc_card_for_id(npc_id)
			var npc_name := str(npc_card.get("name", str(npc_card_detail.get("name", "附近角色"))))
			var proactive_quotes := _fallback_trade_quotes(npc_card_detail)
			var proactive_dialogue_shell := {
				"npc_id": npc_id,
				"district": _current_district_for_position(player.position),
				"topic_id": "",
				"approach": "friendly",
				"intent": "继续追问",
				"source": "shell",
				"title": "%s 主动搭话" % npc_name,
				"body": "%s 朝你看了一眼，像是在等你先开口。你可以先看对方的身份和报价，再决定怎么问。" % npc_name,
				"npc_name": npc_name,
				"trade_quotes": proactive_quotes,
			}
			_open_dialogue_shell(
				proactive_dialogue_shell,
				str(proactive_dialogue_shell.get("title", "%s 主动搭话" % npc_name)),
				str(proactive_dialogue_shell.get("body", "对方正在等你先开口。"))
			)
			status_label.text = "交谈面板已打开，输入后再发问。"
			return
		return
	var nearby_npcs := _get_nearby_npcs(3)
	if nearby_npcs.is_empty():
		return
	for npc_card in nearby_npcs:
		var npc_id := str(npc_card.get("id", ""))
		if npc_id.is_empty() or not npc_views.has(npc_id):
			continue
		if npc_id == npc_last_auto_talker and nearby_npcs.size() > 1:
			continue
		var view: NPCView = npc_views[npc_id]
		var distance := float(npc_card.get("distance", 99999.0))
		if distance > NPC_AUTO_TALK_RADIUS * WORLD_VISUAL_SCALE:
			continue
		var proactive_interest := clampf(float(view.npc_data.get("proactive_interest", 0.32)), 0.12, 0.92)
		if music_rng.randf() > proactive_interest:
			continue
		npc_auto_talk_elapsed = 0.0
		npc_last_auto_talker = npc_id
		view.trigger_social_beat(player.position, true, "speaker", 1.08, 1.0)
		var npc_card_detail := _npc_card_for_id(npc_id)
		var npc_name := str(npc_card.get("name", str(npc_card_detail.get("name", "附近角色"))))
		var proactive_quotes := _fallback_trade_quotes(npc_card_detail)
		active_dialogue_context = {
			"npc_id": npc_id,
			"district": _current_district_for_position(player.position),
			"topic_id": "",
			"approach": "friendly",
			"intent": "继续追问",
			"npc_name": npc_name,
			"trade_quotes": proactive_quotes
		}
		var clean_proactive_dialogue := {
			"npc_id": npc_id,
			"district": _current_district_for_position(player.position),
			"topic_id": "",
			"approach": "friendly",
			"intent": "主动搭话",
			"source": "shell",
			"title": "%s 主动搭话" % npc_name,
			"body": "%s 朝你看了一眼，像是在等你先开口。你可以先看对方的身份和报价，再决定怎么问。" % npc_name,
			"npc_name": npc_name,
			"trade_quotes": proactive_quotes
		}
		_open_dialogue_shell(clean_proactive_dialogue, str(clean_proactive_dialogue.get("title", "街头交谈")), str(clean_proactive_dialogue.get("body", "")))
		status_label.text = "交谈面板已打开，输入后再发问。"
		return
		active_dialogue_context = {
			"npc_id": npc_id,
			"district": _current_district_for_position(player.position),
			"topic_id": "",
			"approach": "friendly",
			"intent": "主动搭话",
			"npc_name": npc_name,
			"trade_quotes": proactive_quotes
		}
		var proactive_dialogue_shell := {
			"npc_id": npc_id,
			"district": _current_district_for_position(player.position),
			"topic_id": "",
			"approach": "friendly",
			"intent": "涓诲姩鎼瘽",
			"source": "shell",
			"title": "%s 涓诲姩鎼瘽" % npc_name,
			"body": "%s 朝你看了一眼，像是在等你先开口。你可以先看对方的身份和报价，再决定怎么问。" % npc_name,
			"npc_name": npc_name,
			"trade_quotes": proactive_quotes
		}
		_open_dialogue_shell(
			proactive_dialogue_shell,
			str(proactive_dialogue_shell.get("title", "%s 涓诲姩鎼瘽" % npc_name)),
			str(proactive_dialogue_shell.get("body", "瀵规柟姝ｅ湪绛変綘鍏堝紑鍙ｃ€?"))
		)
		status_label.text = "宸叉墦寮€浜よ皥闈㈡澘锛岃緭鍏ュ悗鍐嶅彂闂€?"
		return
		var proactive_dialogue := {}
		pending_dialogue_request["player_input"] = ""
		pending_dialogue_request["started_msec"] = Time.get_ticks_msec()
		pending_dialogue_request["retry_count"] = 0
		var live_scene := _build_scene_observation_payload(false)
		UiRouter.push_modal(
			"%s 主动搭话" % npc_name,
			"对方正在整理想法……",
			"conversation",
			{"dialogue": {
				"npc_id": npc_id,
				"district": _current_district_for_position(player.position),
				"topic_id": "",
				"approach": "cautious",
				"source": "pending",
				"title": "%s 主动搭话" % npc_name,
				"body": "对方正在整理想法……",
				"npc_name": npc_name,
				"trade_quotes": proactive_quotes
			}}
		)
		status_label.text = "对方正在整理说法……"
		modal_send_button.disabled = true
		ApiClient.post_json("/npc/player_talk", {
			"npc_id": npc_id,
			"district": _current_district_for_position(player.position),
			"topic_id": "",
			"approach": "friendly",
			"intent": "主动搭话",
			"player_position": live_scene.get("player_position", {}),
			"screenshot_b64": "",
			"scene_context": live_scene.get("scene_context", {})
		}, "player_talk")
		return

func _talk_topics_for_npc(npc_id: String, district_name: String) -> Array:
	var topics: Array = GameState.snapshot.get("talk_topics", [])
	var filtered: Array = []
	for raw_topic in topics:
		var topic: Dictionary = raw_topic
		var npc_ids: Array = topic.get("npc_ids", [])
		if not npc_ids.is_empty() and not npc_ids.has(npc_id):
			continue
		var topic_district := str(topic.get("district", ""))
		if not topic_district.is_empty() and topic_district != district_name:
			continue
		filtered.append(topic)
	filtered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("heat", 0.0)) > float(b.get("heat", 0.0))
	)
	return filtered.slice(0, min(2, filtered.size()))


func _approach_label(approach: String) -> String:
	match approach:
		"friendly":
			return "拉近关系"
		"hardball":
			return "直接逼问"
		_:
			return "试探"


func _topic_intent(topic: Dictionary) -> String:
	match str(topic.get("kind", "")):
		"labor":
			return "问工作"
		"livelihood":
			return "问账本"
		"ration":
			return "问口粮"
		"asset":
			return "试盘口"
		"position":
			return "问押注"
		"family":
			return "问家族"
		"company":
			return "问公司"
		"institution":
			return "问机构"
		"panic":
			return "问谁在放风"
		_:
			return "问风声"


func _open_dialogue_shell(dialogue_context: Dictionary, title: String, body: String) -> void:
	active_dialogue_context = dialogue_context.duplicate(true)
	pending_dialogue_request = {}
	modal_send_button.disabled = false
	UiRouter.push_modal(
		title,
		body,
		"conversation",
		{"dialogue": dialogue_context}
	)


func _npc_card_for_id(npc_id: String) -> Dictionary:
	var cards: Array = GameState.snapshot.get("npc_cards", [])
	for raw_card in cards:
		var card: Dictionary = raw_card
		if str(card.get("id", "")) == npc_id:
			return card
	return {}


func _npc_relation_status(card: Dictionary) -> String:
	var status := str(card.get("relation_status", ""))
	if status.is_empty():
		return "还在观察你"
	return status


func _npc_relation_color(status: String) -> Color:
	match status:
		"防着你":
			return Color("8a3c2d")
		"愿意卖消息":
			return Color("2f6a4d")
		"愿意继续聊":
			return Color("4d6f2f")
		"记得你来问过":
			return Color("7b5d34")
		_:
			return Color("6c5538")


func _npc_brief_line(card: Dictionary) -> String:
	var llm_line := str(card.get("llm_line", ""))
	if not llm_line.is_empty():
		return llm_line
	return str(card.get("brief_history_summary", ""))


func _refresh_interaction_badge() -> void:
	if inspection_mode:
		interaction_badge_label.text = ""
		return
	if interior_mode:
		if current_interactable != null:
			interaction_badge_label.text = "E %s  ·  %s" % [current_interactable.title, current_interactable.subtitle]
		else:
			interaction_badge_label.text = "屋内走动中  ·  靠近床、灶台、储物箱或账桌后按 E"
		return
	if current_interactable != null:
		if current_interactable.kind == "house":
			interaction_badge_label.text = "F 进入 %s  ·  %s  ·  H 账本  ·  Tab 查看模式" % [current_interactable.title, current_interactable.subtitle]
			return
		interaction_badge_label.text = "E %s  ·  %s  ·  H 账本  ·  Tab 查看模式" % [current_interactable.title, current_interactable.subtitle]
		return
	var nearby_npcs := _get_nearby_npcs(1)
	if not nearby_npcs.is_empty():
		var npc_id := str(nearby_npcs[0].get("id", ""))
		var card := _npc_card_for_id(npc_id)
		var relation_status := _npc_relation_status(card)
		var brief_line := _npc_brief_line(card)
		var social_prompt := str(GameState.snapshot.get("quick_hud", {}).get("social_prompt", ""))
		if social_prompt.is_empty():
			if brief_line.is_empty():
				interaction_badge_label.text = "E 与 %s 交谈  ·  %s  ·  H 账本" % [str(nearby_npcs[0].get("name", "附近角色")), relation_status]
			else:
				interaction_badge_label.text = "E 与 %s 交谈  ·  %s  ·  %s" % [str(nearby_npcs[0].get("name", "附近角色")), relation_status, brief_line]
		else:
			interaction_badge_label.text = "E 与 %s 交谈  ·  %s  ·  最热话题：%s" % [str(nearby_npcs[0].get("name", "附近角色")), relation_status, social_prompt]
	else:
		interaction_badge_label.text = "靠近摊位、告示板、工牌或席位后按 E  ·  H 账本  ·  Tab 查看模式"


func _move_player(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	last_move_input = input_vector
	player.set_movement_direction(input_vector)
	var world_size := WORLD_RECT.size * WORLD_VISUAL_SCALE
	var desired_position := Vector2(
		clampf(player.position.x + input_vector.x * PLAYER_SPEED * delta, 0.0, world_size.x),
		clampf(player.position.y + input_vector.y * PLAYER_SPEED * delta, 0.0, world_size.y)
	)
	var desired_layout_position := desired_position / WORLD_VISUAL_SCALE
	if WorldLayout.is_walkable_point(desired_layout_position):
		player.position = desired_position
		return
	var slide_x_position := Vector2(desired_position.x, player.position.y)
	if WorldLayout.is_walkable_point(slide_x_position / WORLD_VISUAL_SCALE):
		player.position = slide_x_position
		return
	var slide_y_position := Vector2(player.position.x, desired_position.y)
	if WorldLayout.is_walkable_point(slide_y_position / WORLD_VISUAL_SCALE):
		player.position = slide_y_position


func _update_world_camera(delta: float) -> void:
	var target_offset := Vector2.ZERO
	if last_move_input.length() > 0.08:
		target_offset = last_move_input.normalized() * CAMERA_LOOKAHEAD_DISTANCE
	camera_focus_offset = camera_focus_offset.lerp(target_offset, minf(1.0, delta * CAMERA_LOOKAHEAD_LERP))
	world_camera.position = player.position + camera_focus_offset


func _update_npc_attention() -> void:
	if interior_mode:
		return
	for npc_id in npc_views.keys():
		var view: NPCView = npc_views[npc_id]
		var distance := player.position.distance_to(view.position)
		var social_radius: float = max(view.get_social_radius(), 1.0)
		var attention: float = 0.0
		if distance <= social_radius * 0.42:
			attention = 1.0 - distance / (social_radius * 0.56)
		elif distance <= 72.0 * WORLD_VISUAL_SCALE:
			attention = 0.08
		view.set_observer_target(player.position, attention)
		view.set_presence_focus(maxf(attention, clampf(1.0 - distance / (94.0 * WORLD_VISUAL_SCALE), 0.0, 1.0)))


func _current_district_for_position(pos: Vector2) -> String:
	if interior_mode:
		return house_interior.get_current_district()
	var backend_pos := pos / WORLD_VISUAL_SCALE
	return WorldLayout.district_for_point(backend_pos)


func _current_subregion_for_position(pos: Vector2) -> String:
	if interior_mode:
		return ""
	var backend_pos := pos / WORLD_VISUAL_SCALE
	return WorldLayout.subregion_name_for_point(backend_pos)


func _update_current_interactable() -> void:
	if interior_mode:
		current_interactable = house_interior.get_current_interactable()
		hint_label.text = house_interior.get_hint_text()
		return
	var nearby_npcs := _get_nearby_npcs(1, DIRECT_TALK_RADIUS * WORLD_VISUAL_SCALE)
	var nearest_npc_distance := 99999.0
	if not nearby_npcs.is_empty():
		nearest_npc_distance = float(nearby_npcs[0].get("distance", 99999.0))
	var previous_interactable := current_interactable
	var nearest: InteractableView = null
	var nearest_house: InteractableView = null
	var best_distance := 99999.0
	var best_house_distance := 99999.0
	for node in interactables:
		var anchor := _interaction_anchor_for_node(node)
		var distance := player.position.distance_to(anchor)
		var interaction_radius := _interaction_radius_for_node(node)
		node.set_focus_strength(clampf(1.0 - distance / (interaction_radius * 1.35), 0.0, 1.0))
		if node.kind == "house":
			if distance < interaction_radius and distance < best_house_distance:
				best_house_distance = distance
				nearest_house = node
		elif distance < interaction_radius and distance < best_distance:
			best_distance = distance
			nearest = node
	if nearest_house != null:
		nearest = nearest_house
	for node in interactables:
		node.set_highlighted(node == nearest)
	current_interactable = nearest
	for node in interactables:
		node.set_highlighted(node == current_interactable)
	if ledger_ui_visible and previous_interactable != current_interactable:
		_open_interactable_actions()
	if current_interactable == null:
		if nearby_npcs.is_empty():
			hint_label.text = "四处走动。靠近摊位、告示板、交易席位或工牌后按 E 打开操作。F3 显示听觉圈，Tab 切换查看模式。"
		else:
			hint_label.text = "附近有人。按 E 可直接搭话，或继续走向摊位和告示板。F3 显示听觉圈，Tab 切换查看模式。"
	else:
		if current_interactable.kind == "house":
			hint_label.text = "靠近 %s 时会弹出入屋提示，按 F 进入房间。%s  H 开关账本界面，Tab 临时取消遮挡。" % [current_interactable.title, current_interactable.subtitle]
		else:
			hint_label.text = "靠近 %s。按 E 进行操作。%s  H 开关账本界面，Tab 临时取消遮挡。" % [current_interactable.title, current_interactable.subtitle]


func _interaction_anchor_for_node(node: InteractableView) -> Vector2:
	var anchor := node.position
	if node.kind == "house" and WorldLayout.has_house_door(node.interaction_id):
		anchor = _to_world_position(WorldLayout.snap_to_walkable(WorldLayout.house_door_for_id(node.interaction_id)))
	return anchor


func _interaction_radius_for_node(node: InteractableView) -> float:
	if node.kind == "house":
		match node.interaction_id:
			"exchange_house", "stock_exchange_6":
				return 104.0 * WORLD_VISUAL_SCALE
			"bookstore_5":
				return 180.0 * WORLD_VISUAL_SCALE
			"news_center_1":
				return 168.0 * WORLD_VISUAL_SCALE
			"capitalist_mansion_7":
				return 152.0 * WORLD_VISUAL_SCALE
			"bar_8", "food_market_3", "food_market_4":
				return 112.0 * WORLD_VISUAL_SCALE
			_:
				return 104.0 * WORLD_VISUAL_SCALE
	return 78.0 * WORLD_VISUAL_SCALE


func _exchange_house_node() -> InteractableView:
	for node in interactables:
		if node.kind == "house" and node.interaction_id == "exchange_house":
			return node
	return null


func _exchange_entry_zone(node: InteractableView) -> Rect2:
	var center := _interaction_anchor_for_node(node)
	return Rect2(center + Vector2(-188.0, -44.0), Vector2(376.0, 236.0))


func _nearest_house_for_entry() -> InteractableView:
	var nearest: InteractableView = null
	var best_distance := INF
	for node in interactables:
		if node.kind != "house":
			continue
		var anchor := _interaction_anchor_for_node(node)
		var distance := player.position.distance_to(anchor)
		var interaction_radius := _interaction_radius_for_node(node)
		if distance > interaction_radius:
			continue
		if distance < best_distance:
			best_distance = distance
			nearest = node
	return nearest


func _maybe_trigger_auto_house_entry() -> void:
	return


func _open_interactable_actions() -> void:
	_play_player_interaction(_context_focus_direction(), _context_interaction_mode())
	if current_interactable == null:
		var nearby_npcs := _get_nearby_npcs(1, DIRECT_TALK_RADIUS * WORLD_VISUAL_SCALE)
		if not nearby_npcs.is_empty():
			var npc_id := str(nearby_npcs[0].get("id", ""))
			if npc_views.has(npc_id):
				var preview_view: NPCView = npc_views[npc_id]
				preview_view.trigger_social_beat(player.position, false, "listener", 0.85, 0.75)
	for child in action_panel.get_children():
		child.queue_free()

	var current_district := _current_district_for_position(player.position if not interior_mode else house_interior.get_player_position())
	var current_subregion := _current_subregion_for_position(player.position if not interior_mode else house_interior.get_player_position())
	var title := Label.new()
	var area_label := current_district if current_subregion.is_empty() else "%s · %s" % [current_district, current_subregion]
	title.text = "当前位置：%s%s" % [area_label, " · 屋内" if interior_mode else ""]
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("3a2819"))
	action_panel.add_child(title)

	if current_interactable == null:
		var empty := Label.new()
		empty.text = "这里没有固定装置，但你可以找附近 NPC 搭话，或者直接触发演示控制。"
		empty.add_theme_color_override("font_color", Color("4b3926"))
		action_panel.add_child(empty)
	else:
		var interact_label := Label.new()
		interact_label.text = "%s [%s]" % [current_interactable.title, current_interactable.district]
		interact_label.add_theme_font_size_override("font_size", 16)
		interact_label.add_theme_color_override("font_color", Color("5e3d24"))
		action_panel.add_child(interact_label)
		_add_context_actions(current_interactable)

	if not interior_mode:
		_add_nearby_npc_actions(current_district)
		_add_collective_actions(current_district, current_subregion)
	_add_action_button("手动触发 AI 脉冲", {"action_type":"manual_pulse"})
	_add_action_button("测试 AI 连接", {"action_type":"probe_ai"})
	_add_action_button("重置世界到第一天", {"action_type":"reset_world"})


func _trigger_primary_interaction() -> void:
	var payload := _default_payload_for_current_context()
	if payload.is_empty():
		if not interior_mode and current_interactable != null and current_interactable.kind == "house" and not ledger_ui_visible:
			GameState.add_toast("靠近门口后按 F 进入 %s。" % current_interactable.title)
			return
		if ledger_ui_visible:
			_open_interactable_actions()
		else:
			GameState.add_toast("附近没有可直接交互的对象。")
		return
	_submit_interaction(payload)
	if ledger_ui_visible and _payload_requires_panel(payload):
		_open_interactable_actions()


func _default_payload_for_current_context() -> Dictionary:
	var nearby_npcs := _get_nearby_npcs(1, DIRECT_TALK_RADIUS * WORLD_VISUAL_SCALE)
	if not nearby_npcs.is_empty():
		var npc_id := str(nearby_npcs[0].get("id", ""))
		if not npc_id.is_empty():
			return {
				"action_type":"player_talk",
				"district": _current_district_for_position(player.position),
				"payload":{
					"npc_id": npc_id,
					"npc_name": str(nearby_npcs[0].get("name", "附近角色")),
					"approach":"cautious",
					"intent":"街头搭话",
					"subregion_name": _current_subregion_for_position(player.position)
				}
			}
	if current_interactable != null:
		if current_interactable.kind == "house":
			return {}
		return _default_payload_for_interactable(current_interactable)
	return {}


func _trigger_house_entry_hotkey() -> void:
	if interior_mode:
		return
	if modal_overlay.visible or ledger_ui_visible or inspection_mode or not pending_dialogue_request.is_empty():
		return
	var house_node := current_interactable if current_interactable != null and current_interactable.kind == "house" else _nearest_house_for_entry()
	if house_node == null:
		GameState.add_toast("靠近房门后再按 F。")
		return
	var now := Time.get_ticks_msec()
	if now - last_auto_enter_msec < 240:
		return
	last_auto_enter_msec = now
	_submit_interaction(_default_payload_for_interactable(house_node))


func _default_payload_for_interactable(node: InteractableView) -> Dictionary:
	match node.kind:
		"house":
			return {
				"action_type":"enter_house",
				"district": node.district,
				"payload": _house_payload_for_node(node)
			}
		"work":
			return {"action_type":"work", "district": node.district}
		"info":
			return {"action_type":"gather_info", "district": node.district}
		"tasks":
			var board: Array = GameState.get_task_board()
			if not board.is_empty():
				return {
					"action_type":"accept_task",
					"district": node.district,
					"payload":{"task_id": board[0].get("id", "")}
				}
		"end_day":
			return {"action_type":"end_day", "district": node.district}
		"bed":
			return {
				"action_type":"rest",
				"district": node.district,
				"payload": _current_house_action_payload()
			}
		"kitchen":
			return {
				"action_type":"cook_meal",
				"district": node.district,
				"payload": _current_house_action_payload()
			}
		"storage":
			return {
				"action_type":"search_home",
				"district": node.district,
				"payload": _current_house_action_payload()
			}
		"desk":
			return {
				"action_type":"review_ledger",
				"district": node.district,
				"payload": _current_house_action_payload()
			}
		"exit_house":
			return {"action_type":"exit_house"}
	return {}


func _payload_requires_panel(payload: Dictionary) -> bool:
	var action_type := str(payload.get("action_type", ""))
	return action_type in ["buy_goods", "sell_goods", "buy_stock", "sell_stock", "accept_task", "claim_task"]


func _snapshot_goods_names() -> Array:
	var names: Array = []
	for row in GameState.snapshot.get("goods", []):
		var good_name := str(row.get("name", ""))
		if not good_name.is_empty():
			names.append(good_name)
	if names.is_empty():
		return ["面包", "煤", "罐头"]
	return names


func _snapshot_stock_names() -> Array:
	var names: Array = []
	for row in GameState.snapshot.get("stocks", []):
		var stock_name := str(row.get("name", ""))
		if not stock_name.is_empty():
			names.append(stock_name)
	if names.is_empty():
		return ["海藻食业", "珊瑚金控", "龟甲船运"]
	return names


func _npc_display_role(card: Dictionary, entry: Dictionary = {}) -> String:
	var title := str(card.get("title", ""))
	if title.is_empty():
		title = str(entry.get("title", ""))
	if not title.is_empty():
		return title
	return str(card.get("role", entry.get("role", "路人")))


func _add_context_actions(node: InteractableView) -> void:
	match node.kind:
		"house":
			_add_action_button("推门进屋", {
				"action_type":"enter_house",
				"district": node.district,
				"payload": _house_payload_for_node(node)
			})
		"work":
			_add_action_button("做一轮打工", {"action_type":"work", "district": node.district})
		"goods":
			for good_name in _snapshot_goods_names():
				_add_action_button("买入 %s" % good_name, {"action_type":"buy_goods", "district": node.district, "payload":{"good_name":good_name, "quantity":1}})
				_add_action_button("卖出 %s" % good_name, {"action_type":"sell_goods", "district": node.district, "payload":{"good_name":good_name, "quantity":1}})
		"stocks":
			for stock_name in _snapshot_stock_names():
				_add_action_button("买入 %s" % stock_name, {"action_type":"buy_stock", "district": node.district, "payload":{"stock_name":stock_name, "quantity":1}})
				_add_action_button("卖出 %s" % stock_name, {"action_type":"sell_stock", "district": node.district, "payload":{"stock_name":stock_name, "quantity":1}})
		"info":
			_add_action_button("花 2 铜币打听消息", {"action_type":"gather_info", "district": node.district})
		"tasks":
			var board: Array = GameState.get_task_board()
			for task in board:
				_add_action_button("接任务：%s" % task.get("title", ""), {
					"action_type":"accept_task",
					"district": node.district,
					"payload":{"task_id": task.get("id", "")}
				})
		"end_day":
			_add_action_button("敲钟并结束当天", {"action_type":"end_day", "district": node.district})
		"bed":
			_add_action_button("在木床上小睡片刻", {
				"action_type":"rest",
				"district": node.district,
				"payload": _current_house_action_payload()
			})
			_add_action_button("睡到次日", {"action_type":"end_day", "district": node.district})
		"kitchen":
			_add_action_button("在灶台做一顿热饭", {
				"action_type":"cook_meal",
				"district": node.district,
				"payload": _current_house_action_payload()
			})
		"storage":
			_add_action_button("翻找储物箱", {
				"action_type":"search_home",
				"district": node.district,
				"payload": _current_house_action_payload()
			})
		"desk":
			_add_action_button("在账桌整理账本", {
				"action_type":"review_ledger",
				"district": node.district,
				"payload": _current_house_action_payload()
			})
		"exit_house":
			_add_action_button("离开屋内", {"action_type":"exit_house"})

	var task_summary: Dictionary = GameState.get_task_summary()
	var active_task: Variant = task_summary.get("active_task", null)
	if typeof(active_task) == TYPE_DICTIONARY and not active_task.is_empty():
		_add_action_button("提交任务：%s" % active_task.get("title", ""), {
			"action_type":"claim_task",
			"district": node.district,
			"payload":{"task_id": active_task.get("id", "")}
		})


func _add_nearby_npc_actions(current_district: String) -> void:
	var nearby_npcs := _get_nearby_npcs(3)
	if nearby_npcs.is_empty():
		return
	var subtitle := Label.new()
	subtitle.text = "附近人物"
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("5e3d24"))
	action_panel.add_child(subtitle)
	for entry in nearby_npcs:
		var npc_id := str(entry.get("id", ""))
		var npc_name := str(entry.get("name", "陌生人"))
		var card := _npc_card_for_id(npc_id)
		var npc_role := _npc_display_role(card, entry)
		var relation_status := _npc_relation_status(card)
		if not card.is_empty():
			var status_label := Label.new()
			status_label.text = "  %s" % relation_status
			status_label.add_theme_color_override("font_color", _npc_relation_color(relation_status))
			status_label.add_theme_font_size_override("font_size", 13)
			action_panel.add_child(status_label)
			var card_label := Label.new()
			card_label.text = "  %s" % str(card.get("personal_summary", ""))
			card_label.add_theme_color_override("font_color", Color("6c5538"))
			card_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			action_panel.add_child(card_label)
			var memory_label := Label.new()
			memory_label.text = "  %s" % str(card.get("memory_summary", ""))
			memory_label.add_theme_color_override("font_color", Color("7a6448"))
			memory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			action_panel.add_child(memory_label)
			var brief_line := _npc_brief_line(card)
			if not brief_line.is_empty():
				var brief_label := Label.new()
				brief_label.text = "  口风：%s" % brief_line
				brief_label.add_theme_color_override("font_color", Color("5a6d46"))
				brief_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				action_panel.add_child(brief_label)
		_add_action_button("与 %s 交谈 [%s · %s]" % [npc_name, npc_role, relation_status], {
			"action_type":"player_talk",
			"district": current_district,
			"payload":{"npc_id": npc_id, "approach":"cautious", "intent":"问风声"}
		})
		var topics := _talk_topics_for_npc(npc_id, current_district)
		for raw_topic in topics:
			var topic: Dictionary = raw_topic
			var approaches: Array = topic.get("approaches", ["cautious"])
			if approaches.is_empty():
				approaches = ["cautious"]
			var intent := _topic_intent(topic)
			var primary_approach := str(approaches[0])
			_add_action_button("%s · %s" % [intent, str(topic.get("label", "街头风向"))], {
				"action_type":"player_talk",
				"district": current_district,
				"payload":{
					"npc_id": npc_id,
					"topic_id": str(topic.get("id", "")),
					"approach": primary_approach,
					"intent": intent
				}
			})
			if topics[0] == topic and approaches.size() > 1:
				_add_action_button("%s · %s" % [_approach_label(str(approaches[1])), str(topic.get("label", "街头风向"))], {
					"action_type":"player_talk",
					"district": current_district,
					"payload":{
						"npc_id": npc_id,
						"topic_id": str(topic.get("id", "")),
						"approach": str(approaches[1]),
						"intent": intent
					}
				})


func _add_collective_actions(current_district: String, current_subregion: String) -> void:
	var actions: Array = []
	for raw_action in GameState.snapshot.get("active_collective_actions", []):
		var action: Dictionary = raw_action
		var district := str(action.get("district", ""))
		var scope := str(action.get("scope", "district"))
		if scope != "city" and district != current_district:
			continue
		actions.append(action)
	if actions.is_empty():
		return
	var subtitle := Label.new()
	subtitle.text = "附近现场"
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("7b4026"))
	action_panel.add_child(subtitle)
	for raw_action in actions.slice(0, 2):
		var action: Dictionary = raw_action
		var line := Label.new()
		var site_label := str(action.get("target_location_title", action.get("target_subregion_name", current_district)))
		var stage_label := str(action.get("stage_label", "听说"))
		var resolution_label := str(action.get("resolution_label", ""))
		line.text = "  %s [%s @ %s]" % [str(action.get("label", "集体行动")), resolution_label if not resolution_label.is_empty() else stage_label, site_label]
		line.add_theme_color_override("font_color", Color("6a4a31"))
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		action_panel.add_child(line)
		var note := Label.new()
		var response_note := str(action.get("resolution_note", action.get("response_note", "")))
		if response_note.is_empty():
			response_note = "现场正在重新抬价、压场或试探口风。"
		note.text = "  %s" % response_note
		note.add_theme_color_override("font_color", Color("7a6448"))
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		action_panel.add_child(note)
		if not resolution_label.is_empty():
			continue
		if not current_subregion.is_empty() and current_subregion != str(action.get("target_subregion_name", current_subregion)):
			_add_action_button("赶去 %s 围观" % site_label, {
				"action_type":"collective_intervene",
				"district": current_district,
				"payload":{
					"action_id": str(action.get("id", "")),
					"mode":"mediate"
				}
			})
			continue
		_add_action_button("给 %s 撑场" % str(action.get("label", "现场")), {
			"action_type":"collective_intervene",
			"district": current_district,
			"payload":{
				"action_id": str(action.get("id", "")),
				"mode":"support"
			}
		})
		_add_action_button("替双方斡旋", {
			"action_type":"collective_intervene",
			"district": current_district,
			"payload":{
				"action_id": str(action.get("id", "")),
				"mode":"mediate"
			}
		})
		_add_action_button("帮机构压场", {
			"action_type":"collective_intervene",
			"district": current_district,
			"payload":{
				"action_id": str(action.get("id", "")),
				"mode":"suppress"
			}
		})


func _add_action_button(label_text: String, payload: Dictionary) -> void:
	var button := Button.new()
	button.text = label_text
	_style_button(button, Color("6c4a2a"), Color("8a6037"), Color("4f3520"))
	button.pressed.connect(_submit_interaction.bind(payload))
	action_panel.add_child(button)


func _style_button(button: Button, normal: Color, hover: Color, pressed: Color) -> void:
	button.add_theme_color_override("font_color", Color("f6e6c7"))
	button.add_theme_stylebox_override("normal", _make_button_style(normal))
	button.add_theme_stylebox_override("hover", _make_button_style(hover))
	button.add_theme_stylebox_override("pressed", _make_button_style(pressed))


func _make_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("2a1a11")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style


func _make_chip_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("2a1a11")
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _submit_interaction(payload: Dictionary) -> void:
	var action_type := str(payload.get("action_type", ""))
	_play_player_interaction(_interaction_focus_direction(payload), _interaction_mode(payload))
	_preview_player_action_reaction(payload)
	if action_type == "player_talk":
		var target_id := str(payload.get("payload", {}).get("npc_id", ""))
		if npc_views.has(target_id):
			var target_view: NPCView = npc_views[target_id]
			target_view.trigger_social_beat(player.position, false, "listener", 1.05, 1.0)
	if action_type == "enter_house":
		pending_player_reaction = {}
		var node_payload: Dictionary = payload.get("payload", {})
		_set_interior_mode(true, {
			"id": str(node_payload.get("house_id", "")),
			"state_house_id": str(node_payload.get("state_house_id", node_payload.get("house_id", ""))),
			"action_house_id": str(node_payload.get("action_house_id", node_payload.get("state_house_id", node_payload.get("house_id", "")))),
			"title": str(node_payload.get("house_title", "屋内")),
			"subtitle": str(node_payload.get("house_subtitle", "床铺、厨房和储物箱都在里面。")),
			"district": str(payload.get("district", _current_district_for_position(player.position)))
		})
	elif action_type == "exit_house":
		pending_player_reaction = {}
		_set_interior_mode(false)
	elif action_type == "end_day":
		_store_pending_player_reaction("end_day", payload)
		ApiClient.post_json("/world/end_day", payload, "end_day")
	elif action_type == "manual_pulse":
		pending_player_reaction = {}
		_request_ai_pulse("manual_scene", true)
	elif action_type == "probe_ai":
		pending_player_reaction = {}
		ApiClient.post_json("/ai/probe", {}, "probe_ai")
	elif action_type == "reset_world":
		pending_player_reaction = {}
		ApiClient.post_json("/world/reset", {}, "reset_world")
	elif action_type == "player_talk":
		pending_player_reaction = {}
		var npc_id := str(payload.get("payload", {}).get("npc_id", ""))
		var npc_card_shell := _npc_card_for_id(npc_id)
		var npc_name_shell := str(payload.get("payload", {}).get("npc_name", ""))
		if npc_name_shell.is_empty():
			npc_name_shell = str(npc_card_shell.get("name", "附近角色"))
		var fallback_quotes_shell := _fallback_trade_quotes(npc_card_shell)
		var request_dialogue_shell := {
			"npc_id": npc_id,
			"district": str(payload.get("district", _current_district_for_position(player.position))),
			"topic_id": str(payload.get("payload", {}).get("topic_id", "")),
			"approach": str(payload.get("payload", {}).get("approach", "cautious")),
			"intent": "继续追问",
			"source": "shell",
			"title": "你与 %s 交谈" % npc_name_shell,
			"body": "[b]%s[/b] 还没开口。你可以先看对方的身份、态度和交易项，再决定怎么问。" % npc_name_shell,
			"npc_name": npc_name_shell,
			"relation_status": str(npc_card_shell.get("relation_status", "还在观察你")),
			"trade_quotes": fallback_quotes_shell,
		}
		_open_dialogue_shell(
			request_dialogue_shell,
			str(request_dialogue_shell.get("title", "街头交谈")),
			str(request_dialogue_shell.get("body", ""))
		)
		status_label.text = "交谈面板已打开，输入后再发问。"
		return
		var npc_card := _npc_card_for_id(str(payload.get("payload", {}).get("npc_id", "")))
		var npc_name := str(payload.get("payload", {}).get("npc_name", ""))
		if npc_name.is_empty():
			npc_name = str(npc_card.get("name", "附近角色"))
		var fallback_quotes := _fallback_trade_quotes(npc_card)
		active_dialogue_context = {
			"npc_id": str(payload.get("payload", {}).get("npc_id", "")),
			"district": str(payload.get("district", _current_district_for_position(player.position))),
			"topic_id": str(payload.get("payload", {}).get("topic_id", "")),
			"approach": str(payload.get("payload", {}).get("approach", "cautious")),
			"intent": "继续追问",
			"npc_name": npc_name,
			"trade_quotes": fallback_quotes,
		}
		var clean_request_dialogue := {
			"npc_id": str(payload.get("payload", {}).get("npc_id", "")),
			"district": str(payload.get("district", "")),
			"topic_id": str(payload.get("payload", {}).get("topic_id", "")),
			"approach": str(payload.get("payload", {}).get("approach", "cautious")),
			"intent": str(payload.get("payload", {}).get("intent", "")),
			"source": "shell",
			"title": "你与 %s 交谈" % npc_name,
			"body": "[b]%s[/b] 还没开口。你可以先看对方的身份、态度和交易项，再决定怎么问。" % npc_name,
			"npc_name": npc_name,
			"relation_status": str(npc_card.get("relation_status", "还在观察你")),
			"trade_quotes": fallback_quotes,
		}
		_open_dialogue_shell(clean_request_dialogue, str(clean_request_dialogue.get("title", "街头交谈")), str(clean_request_dialogue.get("body", "")))
		status_label.text = "交谈面板已打开，输入后再发问。"
		return
		var request_dialogue := {
			"npc_id": str(payload.get("payload", {}).get("npc_id", "")),
			"district": str(payload.get("district", "")),
			"topic_id": str(payload.get("payload", {}).get("topic_id", "")),
			"approach": str(payload.get("payload", {}).get("approach", "cautious")),
			"intent": str(payload.get("payload", {}).get("intent", "")),
			"source": "pending",
			"title": "你与 %s 交谈" % npc_name,
			"body": "[b]%s[/b] 正在整理说法，你也可以先看看对方手里的报价。" % npc_name,
			"npc_name": npc_name,
			"relation_status": str(npc_card.get("relation_status", "还在观察你")),
			"trade_quotes": fallback_quotes,
		}
		active_dialogue_context = {
			"npc_id": str(request_dialogue.get("npc_id", "")),
			"district": str(request_dialogue.get("district", _current_district_for_position(player.position))),
			"topic_id": str(request_dialogue.get("topic_id", "")),
			"approach": str(request_dialogue.get("approach", "cautious")),
			"intent": "继续追问",
			"npc_name": npc_name,
			"trade_quotes": fallback_quotes,
		}
		request_dialogue["source"] = "shell"
		request_dialogue["body"] = "[b]%s[/b] 还没开口。你可以先看对方的身份、态度和交易项，再决定怎么问。" % npc_name
		_open_dialogue_shell(
			request_dialogue,
			str(request_dialogue.get("title", "琛楀ご浜よ皥")),
			str(request_dialogue.get("body", "瀵规柟杩樻病寮€鍙ｏ紝浣犲彲浠ュ厛鎯虫兂鎬庝箞闂€?"))
		)
		status_label.text = "宸叉墦寮€浜よ皥闈㈡澘锛岃緭鍏ュ悗鍐嶅彂闂€?"
		return
		pending_dialogue_request = active_dialogue_context.duplicate(true)
		pending_dialogue_request["player_input"] = ""
		pending_dialogue_request["started_msec"] = Time.get_ticks_msec()
		pending_dialogue_request["retry_count"] = 0
		status_label.text = "对方正在整理说法……"
		UiRouter.push_modal(
			str(request_dialogue.get("title", "街头交谈")),
			str(request_dialogue.get("body", "对方正在整理说法……")),
			"conversation",
			{"dialogue": request_dialogue}
		)
		var live_scene := _build_scene_observation_payload(false)
		ApiClient.post_json("/npc/player_talk", {
			"npc_id": str(request_dialogue.get("npc_id", "")),
			"district": str(request_dialogue.get("district", "")),
			"topic_id": str(request_dialogue.get("topic_id", "")),
			"approach": str(request_dialogue.get("approach", "cautious")),
			"intent": str(request_dialogue.get("intent", "")),
			"player_position": live_scene.get("player_position", {}),
			"screenshot_b64": "",
			"scene_context": live_scene.get("scene_context", {})
		}, "player_talk")
	elif action_type == "trade_action":
		_store_pending_player_reaction("trade_action", payload)
		ApiClient.post_json("/world/action", {
			"action_type": str(payload.get("trade_mode", "")),
			"district": str(payload.get("district", "")),
			"payload": payload.get("payload", {})
		}, "trade_action")
	elif action_type == "accept_task" or action_type == "claim_task":
		_store_pending_player_reaction("task_action", payload)
		ApiClient.post_json("/world/action", {
			"action_type": action_type,
			"district": str(payload.get("district", "")),
			"payload": payload.get("payload", {})
		}, "task_action")
	else:
		_store_pending_player_reaction("action", payload)
		ApiClient.post_json("/world/action", payload, "action")


func _play_player_interaction(direction: Vector2 = Vector2.ZERO, mode: String = "use") -> void:
	if interior_mode:
		return
	player.trigger_interaction(direction, mode)


func _context_focus_direction() -> Vector2:
	if current_interactable != null:
		return _interaction_anchor_for_node(current_interactable) - player.position
	var nearby_npcs := _get_nearby_npcs(1, DIRECT_TALK_RADIUS * WORLD_VISUAL_SCALE)
	if nearby_npcs.is_empty():
		return Vector2.ZERO
	var npc_id := str(nearby_npcs[0].get("id", ""))
	return _npc_focus_direction(npc_id)


func _context_interaction_mode() -> String:
	if current_interactable != null:
		return "use"
	var nearby_npcs := _get_nearby_npcs(1, DIRECT_TALK_RADIUS * WORLD_VISUAL_SCALE)
	return "talk" if not nearby_npcs.is_empty() else "use"


func _interaction_focus_direction(payload: Dictionary) -> Vector2:
	var action_type := str(payload.get("action_type", ""))
	if action_type == "player_talk":
		return _npc_focus_direction(str(payload.get("payload", {}).get("npc_id", "")))
	if current_interactable != null:
		return _interaction_anchor_for_node(current_interactable) - player.position
	return Vector2.ZERO


func _interaction_mode(payload: Dictionary) -> String:
	var action_type := str(payload.get("action_type", ""))
	match action_type:
		"player_talk":
			return "talk"
		"gather_info", "manual_pulse", "probe_ai":
			return "point"
		"search_home":
			return "search"
		"work":
			return "carry"
		"review_ledger", "accept_task", "claim_task", "buy_stock", "sell_stock":
			return "write"
		"cook_meal":
			return "cook"
		"rest", "end_day":
			return "rest"
	return "use"


func _npc_focus_direction(npc_id: String) -> Vector2:
	if npc_views.has(npc_id):
		var view: NPCView = npc_views[npc_id]
		return view.position - player.position
	return Vector2.ZERO


func _poll_world_state() -> void:
	if backend_health_pending:
		return
	if backend_world_state_pending:
		return
	if not pending_dialogue_request.is_empty():
		return
	if modal_overlay.visible:
		return
	var now := Time.get_ticks_msec()
	if not backend_service_ready or now - backend_last_healthcheck_msec >= BACKEND_HEALTHCHECK_MSEC:
		_probe_backend_health()
		return
	backend_world_state_pending = true
	ApiClient.get_json("/world/state", "world_state")


func _handle_cancel_input() -> void:
	if modal_overlay.visible:
		_close_modal()
		return
	if ledger_ui_visible:
		_set_ledger_ui_visible(false)
		return
	if inspection_mode:
		_set_inspection_mode(false)
		return
	if interior_mode:
		_set_interior_mode(false)


func _attempt_service_autostart(force_retry: bool = false) -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	if OS.get_name() != "Windows":
		return false
	var now := Time.get_ticks_msec()
	if not force_retry and now - backend_last_start_msec < BACKEND_RETRY_MSEC:
		return false
	backend_last_start_msec = now
	backend_autostart_attempted = true
	var project_root := ProjectSettings.globalize_path("res://").trim_suffix("/")
	var command := "cd /d \"%s\" && \"%s\" -m uvicorn services.app:app --host 127.0.0.1 --port 8765" % [project_root, _backend_python_executable()]
	backend_process_id = OS.create_process("cmd.exe", PackedStringArray(["/c", command]), false)
	if backend_process_id <= 0:
		backend_process_id = -1
		return false
	status_label.text = "检测到服务未启动，正在自动拉起本地世界引擎…"
	GameState.add_toast("已尝试自动启动本地服务，稍等片刻世界会恢复运转。")
	poll_timer.start(1.4)
	return true


func _backend_python_executable() -> String:
	for candidate in ["C:/Python314/python.exe", "C:/Python313/python.exe", "C:/Python312/python.exe"]:
		if FileAccess.file_exists(candidate):
			return candidate
	return "python"


func _probe_backend_health() -> void:
	backend_health_pending = true
	backend_last_healthcheck_msec = Time.get_ticks_msec()
	ApiClient.get_json("/health", "health")


func _on_ai_pulse_timer_timeout() -> void:
	if not pending_dialogue_request.is_empty():
		return
	if modal_overlay.visible:
		return
	_request_ai_pulse("scheduled_scene", false)


func _request_ai_pulse(trigger: String, show_feedback: bool) -> void:
	var payload := _build_ai_pulse_payload(trigger)
	if show_feedback:
		status_label.text = "正在把场景截图和位置发给 AI……"
	ApiClient.post_json("/ai/pulse", payload, "ai_pulse")


func _build_scene_observation_payload(include_screenshot: bool) -> Dictionary:
	var pulse_position: Vector2 = player.position if not interior_mode else house_interior.get_player_position()
	var current_district := _current_district_for_position(pulse_position)
	var current_subregion := _current_subregion_for_position(pulse_position)
	var task_summary: Dictionary = GameState.get_task_summary()
	var active_task: Variant = task_summary.get("active_task", null)
	var active_task_title := ""
	if typeof(active_task) == TYPE_DICTIONARY and not active_task.is_empty():
		active_task_title = str(active_task.get("title", ""))
	var scene_context := {
		"current_district": current_district,
		"current_subregion": current_subregion,
		"nearby_npcs": _get_nearby_npcs(5),
		"nearby_interactables": _get_nearby_interactables(5),
		"headline_titles": _latest_headline_titles(),
		"active_task_title": active_task_title,
		"player_cash": GameState.get_player().get("cash", 0),
		"location_mode": "interior" if interior_mode else "street",
		"house_title": str(current_house_data.get("title", "")),
		"house_summary": str(_house_state_for_id(str(current_house_data.get("id", ""))).get("summary_line", "")),
	}
	return {
		"current_district": current_district,
		"current_subregion": current_subregion,
		"player_position": {"x": snappedf(pulse_position.x, 0.1), "y": snappedf(pulse_position.y, 0.1)},
		"screenshot_b64": _capture_scene_screenshot_b64() if include_screenshot else "",
		"scene_context": scene_context,
	}


func _build_ai_pulse_payload(trigger: String) -> Dictionary:
	var include_screenshot := trigger == "manual_visual"
	var observation := _build_scene_observation_payload(include_screenshot)
	return {
		"trigger": trigger,
		"current_district": str(observation.get("current_district", "")),
		"current_subregion": str(observation.get("current_subregion", "")),
		"player_position": observation.get("player_position", {}),
		"screenshot_b64": str(observation.get("screenshot_b64", "")),
		"scene_context": observation.get("scene_context", {}),
	}


func _capture_scene_screenshot_b64() -> String:
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		return ""
	image.resize(480, 294)
	var png_bytes: PackedByteArray = image.save_png_to_buffer()
	return Marshalls.raw_to_base64(png_bytes)


func _trigger_proximity_conversation() -> void:
	if modal_overlay.visible or not pending_dialogue_request.is_empty():
		return
	if interior_mode:
		return
	if npc_views.size() < 2:
		return
	var ids := npc_views.keys()
	ids.shuffle()
	for speaker_id in ids:
		var speaker: NPCView = npc_views[speaker_id]
		for listener_id in ids:
			if listener_id == speaker_id:
				continue
			var listener: NPCView = npc_views[listener_id]
			if speaker.get_district() != listener.get_district():
				continue
			if speaker.get_activity() == "working" and listener.get_activity() == "working":
				continue
			if speaker.position.distance_to(listener.position) <= 74.0:
				_play_npc_conversation_beat(speaker, listener)
				var live_scene := _build_scene_observation_payload(false)
				ApiClient.post_json("/npc/conversation", {
					"speaker_id": speaker_id,
					"listener_id": listener_id,
					"trigger": "街头搭话",
					"current_district": str(live_scene.get("current_district", "")),
					"player_position": live_scene.get("player_position", {}),
					"screenshot_b64": "",
					"scene_context": live_scene.get("scene_context", {})
				}, "conversation")
				return


func _play_npc_conversation_beat(speaker, listener) -> void:
	speaker.trigger_social_beat(listener.position, true, "speaker", 0.86, 0.78)
	listener.trigger_social_beat(speaker.position, false, "listener", 0.8, 0.72)


func _find_conversation_bystander(speaker_id: String, listener_id: String, midpoint: Vector2, district: String):
	var candidates: Array = []
	for npc_id in npc_views.keys():
		if npc_id == speaker_id or npc_id == listener_id:
			continue
		var candidate: NPCView = npc_views[npc_id]
		if candidate.get_district() != district:
			continue
		var distance := candidate.position.distance_to(midpoint)
		if distance > 160.0:
			continue
		candidates.append({"view": candidate, "distance": distance})
	if candidates.is_empty():
		return null
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("distance", 99999.0)) < float(b.get("distance", 99999.0))
	)
	return candidates[0].get("view", null)


func _find_conversation_ripple(speaker_id: String, listener_id: String, midpoint: Vector2, district: String, bystander) -> Array:
	var candidates: Array = []
	for npc_id in npc_views.keys():
		if npc_id == speaker_id or npc_id == listener_id:
			continue
		var candidate: NPCView = npc_views[npc_id]
		if bystander != null and candidate == bystander:
			continue
		if candidate.get_district() != district:
			continue
		var distance := candidate.position.distance_to(midpoint)
		if distance <= 160.0 or distance > 250.0:
			continue
		candidates.append({"view": candidate, "distance": distance})
	if candidates.is_empty():
		return []
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("distance", 99999.0)) < float(b.get("distance", 99999.0))
	)
	return candidates.slice(0, min(2, candidates.size()))


func _apply_conversation_ripple(ripple_npcs: Array, midpoint: Vector2) -> void:
	for index in range(ripple_npcs.size()):
		var candidate = ripple_npcs[index].get("view", null)
		if candidate == null:
			continue
		if index == 0:
			candidate.trigger_social_beat(midpoint, false, "glance", 0.72, 0.64)
		else:
			candidate.trigger_social_beat(midpoint, false, "slowpass", 0.94, 0.58)


func _apply_conversation_emotion_wave(pattern: int, speaker, listener, bystander, ripple_npcs: Array, midpoint: Vector2) -> void:
	var pair_emotion := _conversation_pair_emotion(pattern)
	var crowd_emotion := _conversation_crowd_emotion(pattern)
	var profession_seeds: Array = []
	if not pair_emotion.is_empty():
		speaker.trigger_emotion_wave(pair_emotion, midpoint, 0.78, 0.62)
		listener.trigger_emotion_wave(pair_emotion, midpoint, 0.92, 0.74)
		profession_seeds.append({"view": speaker, "emotion": pair_emotion, "social_role": "speaker", "intensity": 0.68})
		profession_seeds.append({"view": listener, "emotion": pair_emotion, "social_role": "listener", "intensity": 0.72})
	if bystander != null and not crowd_emotion.is_empty():
		bystander.trigger_emotion_wave(crowd_emotion, midpoint, 1.08, 0.76)
		profession_seeds.append({"view": bystander, "emotion": crowd_emotion, "social_role": "bystand", "intensity": 0.62})
	for index in range(ripple_npcs.size()):
		var candidate = ripple_npcs[index].get("view", null)
		if candidate == null or crowd_emotion.is_empty():
			continue
		candidate.trigger_emotion_wave(crowd_emotion, midpoint, 0.9 + float(index) * 0.12, 0.64 - float(index) * 0.08)
		profession_seeds.append({
			"view": candidate,
			"emotion": crowd_emotion,
			"social_role": "glance" if index == 0 else "slowpass",
			"intensity": 0.54 - float(index) * 0.08
		})
	var excluded_ids := [
		speaker.get_npc_id(),
		listener.get_npc_id()
	]
	if bystander != null:
		excluded_ids.append(bystander.get_npc_id())
	for ripple in ripple_npcs:
		var ripple_view = ripple.get("view", null)
		if ripple_view != null:
			excluded_ids.append(ripple_view.get_npc_id())
	var echo_npcs := _find_emotion_echo_candidates(excluded_ids, midpoint, speaker.get_district())
	for index in range(echo_npcs.size()):
		var echo = echo_npcs[index]
		var echo_emotion := crowd_emotion
		if crowd_emotion == "hurry" and index > 0:
			echo_emotion = "startled"
		elif crowd_emotion == "startled" and index > 0:
			echo_emotion = "puzzled"
		echo.trigger_emotion_wave(echo_emotion, midpoint, 0.74 + float(index) * 0.08, 0.48 - float(index) * 0.06)
	_apply_profession_chain_reaction(profession_seeds, midpoint, speaker.get_district(), excluded_ids)


func _conversation_pair_emotion(pattern: int) -> String:
	match pattern:
		1:
			return "startled"
		2:
			return "scoff"
		4:
			return "hurry"
		_:
			return "puzzled"


func _conversation_crowd_emotion(pattern: int) -> String:
	match pattern:
		1:
			return "startled"
		4:
			return "hurry"
		3:
			return "scoff"
		_:
			return "puzzled"


func _find_emotion_echo_candidates(excluded_ids: Array, midpoint: Vector2, district: String) -> Array:
	var excluded: Dictionary = {}
	for npc_id in excluded_ids:
		excluded[str(npc_id)] = true
	var candidates: Array = []
	for npc_id in npc_views.keys():
		if excluded.has(str(npc_id)):
			continue
		var candidate: NPCView = npc_views[npc_id]
		if candidate.get_district() != district:
			continue
		var distance := candidate.position.distance_to(midpoint)
		if distance <= 250.0 or distance > 340.0:
			continue
		candidates.append({"view": candidate, "distance": distance})
	if candidates.is_empty():
		return []
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("distance", 99999.0)) < float(b.get("distance", 99999.0))
	)
	var echoes: Array = []
	for item in candidates.slice(0, min(3, candidates.size())):
		var view = item.get("view", null)
		if view != null:
			echoes.append(view)
	return echoes


func _on_api_response(tag: String, data: Dictionary) -> void:
	_confirm_player_action_reaction(tag, data)
	var dialogue_payload: Dictionary = {}
	if tag != "probe_ai":
		backend_service_ready = true
	if tag == "player_talk" or tag == "trade_action" or tag == "world_state":
		backend_error_streak = 0
	if tag == "world_state":
		backend_world_state_pending = false
	if tag == "health":
		backend_health_pending = false
		backend_service_ready = str(data.get("status", "")) == "ok"
		backend_error_streak = 0
		if backend_service_ready:
			status_label.text = "服务在线，正在同步世界状态。"
			ApiClient.get_json("/world/state", "world_state")
		return
	if tag == "player_talk":
		if data.has("world_state"):
			GameState.apply_snapshot(data["world_state"])
		var dialogue_now: Dictionary = data.get("dialogue", {})
		if dialogue_now.is_empty() and data.has("world_state"):
			dialogue_now = data.get("world_state", {}).get("last_dialogue", {})
		pending_dialogue_request = {}
		modal_send_button.disabled = false
		if dialogue_now.is_empty():
			status_label.text = "这轮对话没有拿到有效回复，你可以直接再发一次。"
			if data.has("world_state"):
				UiRouter.update_guide(data["world_state"])
				UiRouter.maybe_present_event(data["world_state"])
			return
		if not active_dialogue_context.is_empty():
			if str(dialogue_now.get("npc_id", "")).is_empty():
				dialogue_now["npc_id"] = str(active_dialogue_context.get("npc_id", ""))
			if str(dialogue_now.get("district", "")).is_empty():
				dialogue_now["district"] = str(active_dialogue_context.get("district", ""))
			if str(dialogue_now.get("topic_id", "")).is_empty():
				dialogue_now["topic_id"] = str(active_dialogue_context.get("topic_id", ""))
			if str(dialogue_now.get("approach", "")).is_empty():
				dialogue_now["approach"] = str(active_dialogue_context.get("approach", "cautious"))
			if str(dialogue_now.get("intent", "")).is_empty():
				dialogue_now["intent"] = str(active_dialogue_context.get("intent", "继续追问"))
			if dialogue_now.get("trade_quotes", []).is_empty():
				dialogue_now["trade_quotes"] = active_dialogue_context.get("trade_quotes", [])
			if str(dialogue_now.get("npc_name", "")).is_empty():
				dialogue_now["npc_name"] = str(active_dialogue_context.get("npc_name", ""))
		dialogue_now["trade_quotes"] = _npc_card_for_id(str(dialogue_now.get("npc_id", ""))).get("trade_quotes", dialogue_now.get("trade_quotes", []))
		if str(dialogue_now.get("title", "")).is_empty():
			dialogue_now["title"] = "你与 %s 交谈" % str(dialogue_now.get("npc_name", "附近角色"))
		if str(dialogue_now.get("render_body", "")).is_empty() and not str(dialogue_now.get("body", "")).is_empty():
			dialogue_now["render_body"] = str(dialogue_now.get("body", ""))
		if str(dialogue_now.get("render_body", "")).is_empty():
			var dialogue_lines_now: Array = dialogue_now.get("lines", [])
			if dialogue_lines_now.size() >= 2:
				dialogue_now["render_body"] = "[b]你[/b]：%s\n\n[b]%s[/b]：%s" % [
					_sanitize_visible_text(str(dialogue_lines_now[0]), "……"),
					str(dialogue_now.get("npc_name", "对方")),
					_sanitize_visible_text(str(dialogue_lines_now[1]), "对方沉默了一会。")
				]
		dialogue_now["title"] = _sanitize_visible_text(str(dialogue_now.get("title", "")), "街头交谈")
		dialogue_now["render_body"] = _sanitize_visible_text(str(dialogue_now.get("render_body", "")), "对方沉默了一会，又看了你一眼。")
		if str(dialogue_now.get("render_body", "")).strip_edges() == "……":
			dialogue_now["render_body"] = "对方这轮没有说出完整的话，你可以直接再问一次。"
		if str(dialogue_now.get("render_body", "")).find("[b]你[/b]：……") >= 0:
			dialogue_now["render_body"] = str(dialogue_now.get("render_body", "")).replace("[b]你[/b]：……", "[b]你[/b]：你先打量了对方一眼，还没正式开口。")
		dialogue_now["body"] = str(dialogue_now.get("render_body", ""))
		active_dialogue_context = dialogue_now.duplicate(true)
		status_label.text = "对方接上话了。"
		_play_player_talk_feedback(dialogue_now)
		UiRouter.push_modal(
			str(dialogue_now.get("title", "街头交谈")),
			str(dialogue_now.get("render_body", "")),
			str(dialogue_now.get("tone", "conversation")),
			{"dialogue": dialogue_now}
		)
		if data.has("world_state"):
			UiRouter.update_guide(data["world_state"])
			UiRouter.maybe_present_event(data["world_state"])
		return
	if tag == "player_talk":
		dialogue_payload = data.get("dialogue", {})
		if dialogue_payload.is_empty() and data.has("world_state"):
			dialogue_payload = data.get("world_state", {}).get("last_dialogue", {})
	if data.has("world_state"):
		GameState.apply_snapshot(data["world_state"])
	if tag == "player_talk":
		var dialogue: Dictionary = dialogue_payload
		pending_dialogue_request = {}
		modal_send_button.disabled = false
		if not dialogue.is_empty():
			status_label.text = "服务在线，正在等待下一轮耳语。"
			if not active_dialogue_context.is_empty():
				if str(dialogue.get("npc_id", "")).is_empty():
					dialogue["npc_id"] = str(active_dialogue_context.get("npc_id", ""))
				if str(dialogue.get("district", "")).is_empty():
					dialogue["district"] = str(active_dialogue_context.get("district", ""))
				if str(dialogue.get("topic_id", "")).is_empty():
					dialogue["topic_id"] = str(active_dialogue_context.get("topic_id", ""))
				if str(dialogue.get("approach", "")).is_empty():
					dialogue["approach"] = str(active_dialogue_context.get("approach", "cautious"))
				if str(dialogue.get("intent", "")).is_empty():
					dialogue["intent"] = str(active_dialogue_context.get("intent", "继续追问"))
				if dialogue.get("trade_quotes", []).is_empty():
					dialogue["trade_quotes"] = active_dialogue_context.get("trade_quotes", [])
				if str(dialogue.get("npc_name", "")).is_empty():
					dialogue["npc_name"] = str(active_dialogue_context.get("npc_name", ""))
				dialogue["trade_quotes"] = _npc_card_for_id(str(dialogue.get("npc_id", ""))).get("trade_quotes", dialogue.get("trade_quotes", []))
			if str(dialogue.get("title", "")).is_empty():
				dialogue["title"] = "你与 %s 交谈" % str(dialogue.get("npc_name", "附近角色"))
			if str(dialogue.get("render_body", "")).is_empty() and not str(dialogue.get("body", "")).is_empty():
				dialogue["render_body"] = str(dialogue.get("body", ""))
			if str(dialogue.get("render_body", "")).is_empty():
				var dialogue_lines: Array = dialogue.get("lines", [])
				if dialogue_lines.size() >= 2:
					dialogue["render_body"] = "[b]你[/b]：%s\n\n[b]%s[/b]：%s" % [
						_sanitize_visible_text(str(dialogue_lines[0]), "……"),
						str(dialogue.get("npc_name", "对方")),
						_sanitize_visible_text(str(dialogue_lines[1]), "对方沉默了一会。")
					]
			dialogue["title"] = _sanitize_visible_text(str(dialogue.get("title", "")), "街头交谈")
			dialogue["render_body"] = _sanitize_visible_text(str(dialogue.get("render_body", "")), "对方沉默了一会，又看了你一眼。")
			if str(dialogue.get("render_body", "")).strip_edges() == "……":
				dialogue["render_body"] = "对方这轮没有说出完整的话，你可以直接再问一次。"
			if str(dialogue.get("render_body", "")).find("[b]你[/b]：……") >= 0:
				dialogue["render_body"] = str(dialogue.get("render_body", "")).replace("[b]你[/b]：……", "[b]你[/b]：你先打量了对方一眼，还没正式开口。")
			dialogue["body"] = str(dialogue.get("render_body", ""))
			_play_player_talk_feedback(dialogue)
			UiRouter.push_modal(
				str(dialogue.get("title", "街头交谈")),
				str(dialogue.get("render_body", "")),
				str(dialogue.get("tone", "conversation")),
				{"dialogue": dialogue}
			)
		else:
			status_label.text = "这轮对话没及时接上。"
			UiRouter.push_modal(
				"街头交谈",
				"对方一时没有答上来，只是谨慎地看着你。",
				"conversation",
				{"dialogue": active_dialogue_context if not active_dialogue_context.is_empty() else GameState.snapshot.get("last_dialogue", {})}
			)
	elif tag == "probe_ai":
		UiRouter.push_modal(
			"AI 连接测试",
			"[b]状态[/b]\n%s" % _sanitize_visible_text(str(data.get("message", "")), "连接已建立，正在等待下一轮脉冲。"),
			"probe"
		)
	if data.has("message") and not str(data["message"]).is_empty():
		GameState.add_toast(_sanitize_visible_text(str(data["message"]), "城里刚有一阵新风声。"))
	elif tag == "world_state":
		backend_service_ready = true
		backend_error_streak = 0
		status_label.text = "服务在线，正在等待下一轮耳语。"
	elif tag == "trade_action" and modal_overlay.visible and not active_dialogue_context.is_empty():
		_refresh_modal_trade_panel(active_dialogue_context)
	if data.has("world_state"):
		UiRouter.update_guide(data["world_state"])
		UiRouter.maybe_present_event(data["world_state"])


func _play_player_talk_feedback(dialogue: Dictionary) -> void:
	var npc_id := str(dialogue.get("npc_id", ""))
	if npc_id.is_empty() or not npc_views.has(npc_id):
		return
	var target: NPCView = npc_views[npc_id]
	var truthfulness := float(dialogue.get("truthfulness", 0.5))
	var confidence := float(dialogue.get("confidence", 0.5))
	var emotion := "puzzled"
	if truthfulness < 0.34:
		emotion = "scoff"
	elif confidence >= 0.72:
		emotion = "startled"
	elif str(dialogue.get("approach", "")) == "hardball":
		emotion = "hurry"
	target.trigger_social_beat(player.position, true, "speaker", 1.18, 1.0)
	target.trigger_emotion_wave(emotion, player.position, 1.02, 0.84)
	var heard_count := int(dialogue.get("heard_by", 0))
	if heard_count <= 0:
		return
	var district := target.get_district()
	var midpoint := (target.position + player.position) * 0.5
	var bystanders: Array = []
	for npc_id_key in npc_views.keys():
		if npc_id_key == npc_id:
			continue
		var candidate: NPCView = npc_views[npc_id_key]
		if candidate.get_district() != district:
			continue
		var distance := candidate.position.distance_to(midpoint)
		if distance > 180.0:
			continue
		bystanders.append({"view": candidate, "distance": distance})
	bystanders.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("distance", 99999.0)) < float(b.get("distance", 99999.0))
	)
	for index in range(min(heard_count, min(4, bystanders.size()))):
		var candidate = bystanders[index].get("view", null)
		if candidate == null:
			continue
		candidate.trigger_social_beat(midpoint, false, "bystand" if index == 0 else "glance", 0.82 + float(index) * 0.08, 0.72 - float(index) * 0.08)
		candidate.trigger_emotion_wave("startled" if confidence >= 0.65 and index == 0 else "puzzled", midpoint, 0.88 + float(index) * 0.08, 0.54 - float(index) * 0.06)


func _handle_api_error_v3(tag: String, status_code: int, message: String) -> void:
	if tag == "health":
		backend_health_pending = false
	if tag == "world_state":
		backend_world_state_pending = false
	if not pending_player_reaction.is_empty() and str(pending_player_reaction.get("tag", "")) == tag:
		pending_player_reaction = {}
	if tag == "player_talk":
		pending_dialogue_request = {}
		modal_send_button.disabled = false
		status_label.text = "这轮追问超时了，你可以直接再发一次。"
		if not message.is_empty():
			news_label.text = "[color=#6f1d1b]%s[/color]" % message
		return
	if tag == "world_state":
		backend_error_streak += 1
		status_label.text = "世界状态刷新延迟，稍后自动重试。"
		if backend_error_streak >= 4 and not backend_health_pending:
			_probe_backend_health()
		return
	if tag == "health":
		backend_error_streak += 1
		if backend_error_streak < 4:
			status_label.text = "本地服务探活延迟，继续重试。"
			return
		backend_service_ready = false
		status_label.text = "本地服务未响应，正在尝试重连。"
		_attempt_service_autostart(true)
		GameState.add_toast("本地服务连续多次未响应，正在尝试重连。")
		return
	backend_error_streak += 1
	backend_service_ready = false
	status_label.text = "请求 %s 失败 (%s)" % [tag, status_code]
	if backend_error_streak >= 3 and not backend_health_pending:
		_probe_backend_health()
		GameState.add_toast("这轮请求失败，正在检查本地服务。")
	if not message.is_empty():
		news_label.text = "[color=#6f1d1b]%s[/color]" % message
	return
	if tag == "health":
		backend_health_pending = false
	if not pending_player_reaction.is_empty() and str(pending_player_reaction.get("tag", "")) == tag:
		pending_player_reaction = {}
	if tag == "player_talk":
		pending_dialogue_request = {}
		modal_send_button.disabled = false
		status_label.text = "这轮追问失败了，你可以直接再发一次。"
		if not message.is_empty():
			news_label.text = "[color=#6f1d1b]%s[/color]" % message
		return
	if tag == "health":
		backend_health_pending = false
	if not pending_player_reaction.is_empty() and str(pending_player_reaction.get("tag", "")) == tag:
		pending_player_reaction = {}
	if tag == "player_talk":
		pending_dialogue_request = {}
		modal_send_button.disabled = false
		status_label.text = "这轮追问失败了，你可以直接再发一次。"
		return
		if not pending_dialogue_request.is_empty():
			pending_dialogue_request["last_error_msec"] = Time.get_ticks_msec()
		status_label.text = "对方还在组织说法，正在重试。"
		return
	backend_error_streak += 1
	if tag == "health":
		if backend_error_streak < 3:
			status_label.text = "本地服务探活延迟，正在重试。"
			return
		backend_service_ready = false
		status_label.text = "服务健康检查失败 (%s)" % status_code
		_attempt_service_autostart(true)
		GameState.add_toast("服务连续多次无响应。正在重试拉起本地 Python 服务。")
	elif tag == "world_state":
		status_label.text = "世界状态同步延迟，下一轮自动重试。"
		GameState.add_toast("本轮同步延迟，下一轮自动重试。")
	else:
		status_label.text = "请求 %s 失败 (%s)" % [tag, status_code]
		if backend_error_streak >= 2:
			_probe_backend_health()
			GameState.add_toast("本轮请求失败，正在检查本地服务。")
	if not message.is_empty():
		news_label.text = "[color=#6f1d1b]%s[/color]" % message


func _handle_api_error_v2(tag: String, status_code: int, message: String) -> void:
	if tag == "health":
		backend_health_pending = false
	if not pending_player_reaction.is_empty() and str(pending_player_reaction.get("tag", "")) == tag:
		pending_player_reaction = {}
	if tag == "player_talk":
		pending_dialogue_request = {}
		modal_send_button.disabled = false
		status_label.text = "这轮追问失败了，你可以直接再发一次。"
		return
		if not pending_dialogue_request.is_empty():
			pending_dialogue_request["last_error_msec"] = Time.get_ticks_msec()
		status_label.text = "对方还在想怎么回你，正在重试。"
		return
	if tag == "health":
		backend_service_ready = false
		backend_error_streak += 1
		status_label.text = "服务健康检查失败 (%s)" % status_code
		_attempt_service_autostart(true)
		GameState.add_toast("服务离线或未启动。正在重试拉起本地 Python 服务。")
	else:
		backend_error_streak += 1
		status_label.text = "请求 %s 失败 (%s)" % [tag, status_code]
		_probe_backend_health()
		GameState.add_toast("本轮同步失败，正在重新检查本地服务。")
	if not message.is_empty():
		news_label.text = "[color=#6f1d1b]%s[/color]" % message


func _handle_api_error(tag: String, status_code: int, message: String) -> void:
	if tag == "health":
		backend_health_pending = false
	if not pending_player_reaction.is_empty() and str(pending_player_reaction.get("tag", "")) == tag:
		pending_player_reaction = {}
	if tag == "player_talk":
		pending_dialogue_request = {}
		modal_send_button.disabled = false
		status_label.text = "这轮追问失败了，你可以直接再发一次。"
		return
		if not pending_dialogue_request.is_empty():
			pending_dialogue_request["last_error_msec"] = Time.get_ticks_msec()
		status_label.text = "对方还在想怎么回你，正在重试。"
		return
	backend_service_ready = false
	backend_error_streak += 1
	status_label.text = "请求 %s 失败 (%s)" % [tag, status_code]
	if tag == "health":
		_attempt_service_autostart(true)
		GameState.add_toast("服务离线或未启动。正在重试拉起本地 Python 服务。")
	else:
		_probe_backend_health()
		GameState.add_toast("本轮同步失败，正在重新检查本地服务。")
	if not message.is_empty():
		news_label.text = "[color=#6f1d1b]%s[/color]" % message
	if tag == "player_talk":
		UiRouter.push_modal(
			"街头交谈",
			"对方没有及时接上话，你先记下了这次接触。",
			"conversation",
			{"dialogue": active_dialogue_context if not active_dialogue_context.is_empty() else GameState.snapshot.get("last_dialogue", {})}
		)


func _on_api_error(tag: String, status_code: int, message: String) -> void:
	if tag == "health":
		backend_health_pending = false
	if not pending_player_reaction.is_empty() and str(pending_player_reaction.get("tag", "")) == tag:
		pending_player_reaction = {}
	if tag == "player_talk":
		if not pending_dialogue_request.is_empty():
			pending_dialogue_request["last_error_msec"] = Time.get_ticks_msec()
		status_label.text = "对方还在想怎么回你，正在重试。"
		return
	backend_service_ready = false
	backend_error_streak += 1
	status_label.text = "请求 %s 失败 (%s)" % [tag, status_code]
	_attempt_service_autostart(true)
	GameState.add_toast("服务离线或未启动。正在重试拉起本地 Python 服务。")
	if not message.is_empty():
		news_label.text = "[color=#6f1d1b]%s[/color]" % message
	if tag == "player_talk":
		UiRouter.push_modal(
			"街头交谈",
			"对方没有及时接话，你先记下了这次接触。",
			"conversation",
			{"dialogue": active_dialogue_context if not active_dialogue_context.is_empty() else GameState.snapshot.get("last_dialogue", {})}
		)


func _scan_music_library() -> void:
	music_library.clear()
	var folder_path := ProjectSettings.globalize_path(MUSIC_LIBRARY_PATH)
	var dir := DirAccess.open(folder_path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name.is_empty():
			break
		if dir.current_is_dir():
			continue
		if file_name.get_extension().to_lower() != "mp3":
			continue
		music_library.append(folder_path.path_join(file_name))
	dir.list_dir_end()
	music_library.sort()


func _advance_visual_clock(delta: float) -> void:
	if not visual_time_synced:
		return
	var previous_minutes := visual_clock_minutes
	visual_cycle_seconds = fposmod(visual_cycle_seconds + delta, VISUAL_DAY_CYCLE_SECONDS)
	var cycle_ratio := visual_cycle_seconds / VISUAL_DAY_CYCLE_SECONDS
	visual_clock_minutes = int(floor(cycle_ratio * 1440.0))
	if visual_clock_minutes < previous_minutes:
		visual_day_offset += 1
	var visual_summary := _compose_visual_macro_summary(GameState.snapshot.get("macro_summary", {}))
	var clock_label := str(visual_summary.get("clock_label", "08:00"))
	var period := str(visual_summary.get("time_period", "day"))
	if clock_label != last_visual_clock_label or period != last_visual_period:
		last_visual_clock_label = clock_label
		last_visual_period = period
		_refresh_visual_macro_state()


func _sync_visual_clock_from_snapshot(snapshot: Dictionary) -> void:
	var base_minutes := posmod(int(snapshot.get("clock_minutes", VISUAL_START_CLOCK_MINUTES)), 1440)
	visual_clock_minutes = base_minutes
	visual_cycle_seconds = float(base_minutes) / 1440.0 * VISUAL_DAY_CYCLE_SECONDS
	visual_day_offset = 0
	visual_time_synced = true
	last_visual_clock_label = ""
	last_visual_period = ""


func _compose_visual_macro_summary(base_summary: Dictionary) -> Dictionary:
	var summary := base_summary.duplicate(true)
	var minutes := visual_clock_minutes
	var clock_label := "%02d:%02d" % [int(minutes / 60), minutes % 60]
	var period := "day"
	var solar_ratio := clampf(cos((float(minutes) - 720.0) / 720.0 * PI), -1.0, 1.0)
	var level := 0.2 + ((solar_ratio + 1.0) * 0.5) * 0.8
	if minutes < 300 or minutes >= 1200:
		period = "night"
	elif minutes < 420:
		period = "dawn"
	elif minutes < 1020:
		period = "day"
	else:
		period = "evening"
	var weather: Dictionary = last_snapshot.get("weather", {})
	var weather_kind := str(weather.get("kind", "sunny"))
	var weather_dim: float = {
		"sunny": 0.0,
		"breezy": 0.01,
		"cloudy": 0.05,
		"overcast": 0.08,
		"rain": 0.08,
		"snow": 0.1,
		"dust": 0.14,
	}.get(weather_kind, 0.0)
	level = snapped(clampf(level - weather_dim, 0.2, 1.0), 0.01)
	summary["clock_label"] = clock_label
	summary["time_period"] = period
	summary["light_level"] = level
	summary["weather"] = weather
	return summary


func _refresh_visual_macro_state() -> void:
	if last_snapshot.is_empty():
		return
	var snapshot := last_snapshot
	var player_data: Dictionary = snapshot.get("player", {})
	var weather: Dictionary = snapshot.get("weather", {})
	var weather_label := _weather_label_cn(str(weather.get("label", "晴天")))
	var district_name := _current_district_for_position(player.position if not interior_mode else house_interior.get_player_position())
	var subregion_name := _current_subregion_for_position(player.position if not interior_mode else house_interior.get_player_position())
	var area_label := district_name
	if not subregion_name.is_empty():
		area_label = "%s · %s" % [district_name, subregion_name]
	var visual_summary := _compose_visual_macro_summary(snapshot.get("macro_summary", {}))
	overview_label.text = "第 %s 天  时刻: %s  现金: %s 铜币\n信用: %s  声望: %s  当前区域: %s\n阶层: %s  货物库存: %s  持股种类: %s" % [
		int(snapshot.get("day", 1)) + visual_day_offset,
		visual_summary.get("clock_label", "08:00"),
		player_data.get("cash", 0),
		player_data.get("credit", 0),
		player_data.get("reputation", 0),
		area_label,
		player_data.get("class_position", "底层"),
		player_data.get("goods_inventory", {}),
		player_data.get("stock_holdings", {}).keys().size()
	]
	status_label.text = "天色: %s  ·  天气: %s  ·  区域: %s  ·  上次 AI 脉冲: %s  ·  新闻数: %s  ·  听觉圈: %s" % [
		visual_summary.get("time_period", "day"),
		weather_label,
		area_label,
		str(snapshot.get("last_pulse_at", "未触发")),
		snapshot.get("global_news", []).size(),
		"开" if show_hearing_debug else "关"
	]
	_update_compact_hud(snapshot, district_name)
	_update_macro(visual_summary)
	_refresh_news_ticker(snapshot)
	_apply_time_of_day(visual_summary)
	ambient.set_weather(weather)
	_update_music(visual_summary, district_name)
	house_interior.set_time_of_day(
		str(visual_summary.get("time_period", "day")),
		float(visual_summary.get("light_level", 1.0))
	)
	house_interior.set_clock_context(
		visual_clock_minutes,
		str(visual_summary.get("clock_label", "08:00"))
	)


func _on_snapshot_updated(snapshot: Dictionary) -> void:
	last_snapshot = snapshot.duplicate(true)
	if not visual_time_synced:
		_sync_visual_clock_from_snapshot(snapshot)
	var player_data: Dictionary = snapshot.get("player", {})
	var weather: Dictionary = snapshot.get("weather", {})
	var weather_label := _weather_label_cn(str(weather.get("label", "晴天")))
	var district_name := _current_district_for_position(player.position if not interior_mode else house_interior.get_player_position())
	var subregion_name := _current_subregion_for_position(player.position if not interior_mode else house_interior.get_player_position())
	var area_label := district_name
	if not subregion_name.is_empty():
		area_label = "%s · %s" % [district_name, subregion_name]
	var visual_summary := _compose_visual_macro_summary(snapshot.get("macro_summary", {}))
	var news_items: Array = snapshot.get("global_news", [])
	overview_label.text = "第 %s 天  时刻: %s  现金: %s 铜币\n信用: %s  声望: %s  当前区域: %s\n阶层: %s  货物库存: %s  持股种类: %s" % [
		int(snapshot.get("day", 1)) + visual_day_offset,
		visual_summary.get("clock_label", "08:00"),
		player_data.get("cash", 0),
		player_data.get("credit", 0),
		player_data.get("reputation", 0),
		area_label,
		player_data.get("class_position", "底层"),
		player_data.get("goods_inventory", {}),
		player_data.get("stock_holdings", {}).keys().size()
	]
	status_label.text = "天色: %s  ·  区域: %s  ·  上次 AI 脉冲: %s  ·  新闻数: %s  ·  听觉圈: %s" % [
		visual_summary.get("time_period", "day"),
		area_label,
		snapshot.get("last_pulse_at", "未触发"),
		news_items.size(),
		"开" if show_hearing_debug else "关"
	]
	status_label.text += "  ·  天气: %s" % weather_label
	_update_compact_hud(snapshot, district_name)
	_update_goods(snapshot.get("goods", []), player_data.get("goods_inventory", {}))
	_update_stocks(snapshot.get("stocks", []), player_data.get("stock_holdings", {}), snapshot.get("stock_trade_tape", []))
	_update_news(news_items)
	_refresh_news_ticker(snapshot)
	_update_families(snapshot.get("families", []))
	_update_macro(visual_summary)
	_apply_time_of_day(visual_summary)
	_update_highlights(snapshot.get("npc_highlights", []))
	_update_tasks(snapshot.get("task_summary", {}), snapshot.get("task_board", []))
	_update_district_labels(snapshot.get("districts", []))
	backdrop.set_district_states(snapshot.get("districts", []))
	foreground.set_house_states(snapshot.get("house_states", {}))
	ambient.set_house_states(snapshot.get("house_states", {}))
	ambient.set_weather(weather)
	_update_music(visual_summary, district_name)
	house_interior.set_time_of_day(
		str(visual_summary.get("time_period", "day")),
		float(visual_summary.get("light_level", 1.0))
	)
	house_interior.set_clock_context(
		visual_clock_minutes,
		str(visual_summary.get("clock_label", "08:00"))
	)
	house_interior.set_exchange_hud_state(snapshot.get("stock_exchange_view", {}))
	house_interior.update_house_state(_house_state_for_id(str(current_house_data.get("id", ""))))
	_update_exchange_terminal(snapshot)
	_refresh_npcs()
	if modal_overlay.visible and not active_dialogue_context.is_empty():
		_refresh_modal_trade_panel(active_dialogue_context)
	_maybe_trigger_news_emotion_wave(news_items, district_name)
	if not interior_mode:
		_update_minimap()


func _update_music(summary: Dictionary, district_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		if is_instance_valid(music_player):
			music_player.stop()
			music_player.stream = null
		return
	if music_player.stream == null or not music_player.playing:
		_play_next_random_track()
	var period := str(summary.get("time_period", "day"))
	var target_volume := -10.8
	if period == "night":
		target_volume = -15.5
	elif period == "evening":
		target_volume = -12.8
	elif period == "dawn":
		target_volume = -12.1
	music_player.volume_db = lerpf(music_player.volume_db, target_volume, 0.18)


func _on_music_finished() -> void:
	_play_next_random_track()


func _play_next_random_track() -> void:
	if music_library.is_empty():
		return
	var choices := music_library.duplicate()
	if choices.size() > 1 and not current_music_path.is_empty():
		choices.erase(current_music_path)
	var next_path := str(choices[music_rng.randi_range(0, choices.size() - 1)])
	var next_stream := _load_music_stream(next_path)
	if next_stream == null:
		return
	current_music_path = next_path
	music_player.stream = next_stream
	music_player.play()


func _load_music_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return null
	var stream := AudioStreamMP3.new()
	stream.data = bytes
	return stream


func _refresh_npcs() -> void:
	var npc_array: Array = GameState.get_npcs()
	var seen: Dictionary = {}
	for data in npc_array:
		var npc_id := str(data.get("id", ""))
		if npc_id.is_empty():
			continue
		seen[npc_id] = true
		var view: NPCView
		if not npc_views.has(npc_id):
			view = NPCView.new()
			npc_layer.add_child(view)
			npc_views[npc_id] = view
		else:
			view = npc_views[npc_id]
		var view_data: Dictionary = data.duplicate(true)
		var backend_pos := _coerce_npc_backend_position(Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0))))
		view_data["x"] = backend_pos.x * WORLD_VISUAL_SCALE
		view_data["y"] = backend_pos.y * WORLD_VISUAL_SCALE
		view_data["social_radius"] = float(data.get("social_radius", 180.0)) * WORLD_VISUAL_SCALE
		view.apply_data(view_data, show_hearing_debug)
	for npc_id in npc_views.keys():
		if not seen.has(npc_id):
			npc_views[npc_id].queue_free()
			npc_views.erase(npc_id)


func _update_goods(goods: Array, inventory: Dictionary) -> void:
	var lines: Array[String] = []
	for item in goods:
		var trend := str(item.get("price_trend", "平"))
		var trend_color := "#6a5a43"
		if trend == "涨":
			trend_color = "#8f2d2d"
		elif trend == "跌":
			trend_color = "#2f6f4f"
		lines.append("[b]%s[/b]  价:%s  库存:%s  [color=%s]波动:%s[/color]" % [
			item.get("name", ""),
			item.get("current_price", 0),
			inventory.get(item.get("name", ""), 0),
			trend_color,
			trend
		])
	goods_label.text = "\n".join(lines)


func _update_stocks_legacy(stocks: Array, holdings: Dictionary) -> void:
	var lines: Array[String] = []
	for item in stocks:
		var sentiment := str(item.get("market_sentiment", "平"))
		var sentiment_color := "#6a5a43"
		if sentiment == "乐观":
			sentiment_color = "#8f2d2d"
		elif sentiment == "恐慌":
			sentiment_color = "#2f6f4f"
		lines.append("[b]%s[/b]  价:%s  持仓:%s  [color=%s]情绪:%s[/color]" % [
			item.get("name", ""),
			item.get("current_price", 0),
			holdings.get(item.get("name", ""), 0),
			sentiment_color,
			sentiment
		])
	stocks_label.text = "\n".join(lines)


func _update_stocks(stocks: Array, holdings: Dictionary, tape: Array) -> void:
	var lines: Array[String] = []
	for item in stocks:
		var sentiment := str(item.get("market_sentiment", "平"))
		var sentiment_color := "#6a5a43"
		if sentiment == "乐观":
			sentiment_color = "#8f2d2d"
		elif sentiment == "恐慌":
			sentiment_color = "#2f6f4f"
		var change_pct := float(item.get("change_pct", 0.0)) * 100.0
		var change_amount := int(item.get("change_amount", 0))
		var turnover := float(item.get("float_turnover", 0.0)) * 100.0
		var change_color := "#6a5a43"
		if change_pct > 0.01:
			change_color = "#8f2d2d"
		elif change_pct < -0.01:
			change_color = "#2f6f4f"
		lines.append("[b]%s[/b]  价%s  持仓:%s  [color=%s]情绪:%s[/color]\n[color=%s]涨跌:%+d / %+.2f%%[/color]  总市值:%s  流通热度:%.1f%%" % [
			item.get("name", ""),
			item.get("current_price", 0),
			holdings.get(item.get("name", ""), 0),
			sentiment_color,
			sentiment,
			change_color,
			change_amount,
			change_pct,
			item.get("market_cap", 0),
			turnover
		])
	if not tape.is_empty():
		var tape_lines: Array[String] = []
		for row in tape.slice(0, min(4, tape.size())):
			tape_lines.append("• %s" % _sanitize_visible_text(str(row.get("anonymous_label", "")), "盘面刚动了一下"))
		lines.append("[b]最近匿名成交[/b]\n%s" % "\n".join(tape_lines))
	stocks_label.text = "\n".join(lines)


func _update_news(news: Array) -> void:
	var lines: Array[String] = []
	for item in news:
		var scope := str(item.get("scope", "district"))
		var scope_tag := "[color=#8f2f33]全城[/color]" if scope == "city" else "[color=#315748]街区[/color]"
		lines.append("%s [b]%s[/b]\n%s\n[i]%s[/i]" % [
			scope_tag,
			_sanitize_visible_text(str(item.get("title", "")), "街头广播"),
			_sanitize_visible_text(str(item.get("body", "")), "城里刚有一阵新风声。"),
			", ".join(item.get("tags", []))
		])
	news_label.text = "\n\n".join(lines)


func _update_families(families: Array) -> void:
	var lines: Array[String] = []
	for item in families:
		lines.append("[b]%s[/b]  现金:%s  声望:%s\n策略:%s\n公开动作:%s\n暗线:%s" % [
			item.get("name", ""),
			item.get("cash", 0),
			item.get("reputation", 0),
			item.get("strategy", ""),
			item.get("public_action", ""),
			item.get("hidden_action", "")
		])
	families_label.text = "\n\n".join(lines)


func _update_macro(summary: Dictionary) -> void:
	if summary.is_empty():
		macro_label.text = ""
		scene_note_label.text = ""
		return
	macro_label.text = "[b]时刻[/b] %s   [b]天色[/b] %s\n[b]利率[/b] %s   [b]景气[/b] %s   [b]楼市[/b] %s\n[b]媒体情绪[/b] %s   [b]工人不满[/b] %s\n[b]城市风向[/b] %s   [b]街头压力[/b] %s" % [
		summary.get("clock_label", "08:00"),
		summary.get("time_period", "day"),
		summary.get("interest_rate", 0),
		summary.get("economy_heat", 0),
		summary.get("housing_heat", 0),
		summary.get("media_sentiment", 0),
		summary.get("worker_unrest", 0),
		summary.get("city_mood", ""),
		summary.get("unrest_bias", "")
	]
	scene_note_label.text = "[b]场景判断[/b] %s\n[i]最近截图[/i] %s" % [
		summary.get("scene_director_note", "AI 还没看见你所在的位置。"),
		summary.get("last_scene_capture_at", "未收到")
	]


func _apply_time_of_day(summary: Dictionary) -> void:
	var light_level := float(summary.get("light_level", 1.0))
	var period := str(summary.get("time_period", "day"))
	world_tint.color = Color(
		lerpf(0.48, 1.0, light_level),
		lerpf(0.5, 1.0, light_level),
		lerpf(0.66, 1.0, light_level),
		1.0
	)
	backdrop.set_time_of_day(period, light_level)
	ambient.set_time_of_day(period, light_level)
	foreground.set_time_of_day(period, light_level)


func _update_highlights(highlights: Array) -> void:
	var lines: Array[String] = []
	for item in highlights:
		lines.append("[b]%s[/b] [%s]\n%s\n[i]%s / %s / %s / 风险 %s[/i]" % [
			item.get("name", ""),
			item.get("district", ""),
			item.get("line", ""),
			item.get("mood", ""),
			item.get("goal", ""),
			item.get("activity", ""),
			item.get("fear", 0)
		])
	highlights_label.text = "\n\n".join(lines)


func _update_tasks(summary: Dictionary, board: Array) -> void:
	var lines: Array[String] = []
	var relations: Dictionary = summary.get("family_relations", {})
	if not relations.is_empty():
		lines.append("[b]关系簿[/b]")
		for family_name in relations.keys():
			lines.append("%s: %s" % [family_name, relations[family_name]])
		lines.append("")
	var active_task: Variant = summary.get("active_task", null)
	if typeof(active_task) == TYPE_DICTIONARY and not active_task.is_empty():
		lines.append("[b]当前任务[/b]")
		lines.append(str(active_task.get("title", "")))
		lines.append(str(active_task.get("description", "")))
		lines.append("")
	lines.append("[b]告示板[/b]")
	for task in board:
		lines.append("%s [%s]\n%s" % [
			task.get("title", ""),
			task.get("family", ""),
			task.get("description", "")
		])
	tasks_label.text = "\n".join(lines)


func _update_district_labels(districts: Array) -> void:
	var current_district := _current_district_for_position(player.position)
	for district_info in districts:
		var district_name := str(district_info.get("name", ""))
		if district_labels.has(district_name):
			var state_label: Label = district_labels[district_name]
			state_label.text = "状态 %s · 人流 %s" % [district_info.get("state", "normal"), district_info.get("traffic", 0)]
		if district_chips.has(district_name):
			var chip: Button = district_chips[district_name]
			var state := str(district_info.get("state", "normal"))
			var chip_style := _make_chip_style(_chip_color(district_name, state, district_name == current_district))
			chip.add_theme_stylebox_override("normal", chip_style)
			chip.add_theme_stylebox_override("disabled", chip_style)


func _update_subtitles() -> void:
	if interior_mode:
		if current_interactable != null:
			subtitle_label.text = "%s：%s\n%s" % [
				current_interactable.title,
				current_interactable.subtitle,
				house_interior.get_scene_note()
			]
		else:
			subtitle_label.text = house_interior.get_scene_note()
		return
	var nearby: Array[String] = []
	for view in npc_views.values():
		var line: String = view.get_current_line()
		if line.is_empty():
			continue
		if player.position.distance_to(view.position) <= view.get_social_radius():
			nearby.append("%s：%s" % [view.name_label.text, line])
	nearby.sort()
	if nearby.is_empty():
		var nearest_npcs := _get_nearby_npcs(1)
		if not nearest_npcs.is_empty():
			var nearest_card := _npc_card_for_id(str(nearest_npcs[0].get("id", "")))
			var relation_status := _npc_relation_status(nearest_card)
			var brief_line := _npc_brief_line(nearest_card)
			if not brief_line.is_empty():
				subtitle_label.text = "%s · %s" % [relation_status, brief_line]
				return
			var memory_summary := str(nearest_card.get("memory_summary", ""))
			if not memory_summary.is_empty():
				subtitle_label.text = "%s · %s" % [relation_status, memory_summary]
				return
		var quick: Dictionary = GameState.snapshot.get("quick_hud", {})
		var fallback_line := str(quick.get("latest_rumor", ""))
		if fallback_line.is_empty():
			fallback_line = str(quick.get("latest_news_body", "附近暂时没人低语。"))
		subtitle_label.text = fallback_line
	else:
		subtitle_label.text = "\n".join(nearby.slice(0, min(3, nearby.size())))


func _update_minimap() -> void:
	minimap.visible = not interior_mode
	if interior_mode:
		return
	minimap.update_snapshot(GameState.snapshot, player.position, interactables, _current_district_for_position(player.position))


func _get_nearby_npcs(limit: int, max_distance: float = -1.0) -> Array:
	if interior_mode:
		return []
	var effective_distance := max_distance if max_distance > 0.0 else 126.0 * WORLD_VISUAL_SCALE
	var ranked: Array = []
	for view in npc_views.values():
		var distance := player.position.distance_to(view.position)
		if distance <= effective_distance:
			ranked.append({
				"id": view.get_npc_id(),
				"name": view.name_label.text,
				"role": view.role_label.text,
				"distance": distance
			})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("distance", 99999.0)) < float(b.get("distance", 99999.0))
	)
	return ranked.slice(0, min(limit, ranked.size()))


func _get_nearby_interactables(limit: int) -> Array:
	if interior_mode:
		return house_interior.get_nearby_interactables(limit)
	var ranked: Array = []
	for node in interactables:
		var distance := player.position.distance_to(node.position)
		if distance <= 240.0 * WORLD_VISUAL_SCALE:
			ranked.append({
				"id": node.interaction_id,
				"title": node.title,
				"kind": node.kind,
				"distance": snappedf(distance, 0.1)
			})
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("distance", 99999.0)) < float(b.get("distance", 99999.0))
	)
	return ranked.slice(0, min(limit, ranked.size()))


func _latest_headline_titles() -> Array:
	var titles: Array = []
	for item in GameState.get_headlines():
		titles.append(str(item.get("title", "")))
	return titles.slice(0, min(3, titles.size()))


func _store_pending_player_reaction(tag: String, payload: Dictionary) -> void:
	var action_type := str(payload.get("action_type", ""))
	if _player_action_preview_emotion(action_type).is_empty() and _player_action_confirm_emotion(action_type, "").is_empty():
		pending_player_reaction = {}
		return
	pending_player_reaction = {
		"tag": tag,
		"action_type": action_type,
		"district": str(payload.get("district", _current_district_for_position(player.position))),
		"payload": payload.get("payload", {})
	}


func _preview_player_action_reaction(payload: Dictionary) -> void:
	if interior_mode:
		return
	var action_type := str(payload.get("action_type", ""))
	var emotion := _player_action_preview_emotion(action_type)
	if emotion.is_empty():
		return
	_trigger_player_action_emotion_wave(action_type, emotion, str(payload.get("district", _current_district_for_position(player.position))), false, "")


func _confirm_player_action_reaction(tag: String, data: Dictionary) -> void:
	if pending_player_reaction.is_empty():
		return
	if str(pending_player_reaction.get("tag", "")) != tag:
		return
	var action_type := str(pending_player_reaction.get("action_type", ""))
	var district := str(pending_player_reaction.get("district", _current_district_for_position(player.position)))
	var message := str(data.get("message", ""))
	var emotion := _player_action_confirm_emotion(action_type, message)
	if not emotion.is_empty():
		_trigger_player_action_emotion_wave(action_type, emotion, district, true, message)
	pending_player_reaction = {}


func _player_action_preview_emotion(action_type: String) -> String:
	match action_type:
		"buy_goods", "sell_goods", "buy_stock", "sell_stock":
			return "puzzled"
		"accept_task", "claim_task":
			return "startled"
		"end_day":
			return "hurry"
	return ""


func _player_action_confirm_emotion(action_type: String, message: String) -> String:
	if message.contains("不足") or message.contains("不够") or message.contains("没有") or message.contains("失败"):
		return "scoff"
	match action_type:
		"buy_stock":
			return "startled"
		"sell_stock":
			return "puzzled"
		"buy_goods":
			return "puzzled"
		"sell_goods":
			return "startled"
		"claim_task":
			return "startled"
		"accept_task":
			return "puzzled"
		"end_day":
			return "hurry"
		"work":
			return "scoff"
		"gather_info":
			return "puzzled"
	return ""


func _trigger_player_action_emotion_wave(action_type: String, emotion: String, district: String, confirmed: bool, message: String) -> void:
	if interior_mode or emotion.is_empty():
		return
	var current_district := _current_district_for_position(player.position)
	if not district.is_empty() and district != current_district and action_type != "end_day":
		return
	var source := player.position
	var radius := 250.0 if not confirmed else 320.0
	if action_type == "end_day":
		radius = 420.0
	var candidates: Array = []
	for npc_id in npc_views.keys():
		var candidate: NPCView = npc_views[npc_id]
		if candidate.get_district() != current_district:
			continue
		var distance := candidate.position.distance_to(source)
		if distance > radius:
			continue
		var bias := _player_action_reaction_bias(candidate, action_type, confirmed)
		if bias <= 0.04:
			continue
		candidates.append({"view": candidate, "distance": distance, "bias": bias, "score": distance - bias * 110.0})
	if candidates.is_empty():
		return
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 99999.0)) < float(b.get("score", 99999.0))
	)
	var limit := 4 if not confirmed else 6
	var profession_seeds: Array = []
	var excluded_ids: Array = []
	for index in range(min(limit, candidates.size())):
		var candidate = candidates[index].get("view", null)
		if candidate == null:
			continue
		excluded_ids.append(candidate.get_npc_id())
		var bias := float(candidates[index].get("bias", 0.0))
		candidate.set_observer_target(source, 0.36 + bias * 0.34 + float(index == 0) * 0.14)
		var social_role := _player_action_social_role(candidate, action_type, confirmed, index)
		var social_intensity: float = maxf(0.22, (0.42 - float(index) * 0.03 + (0.18 if confirmed else 0.0)) * (0.82 + bias * 0.44))
		candidate.trigger_social_beat(source, false, social_role, 0.58 + float(index) * 0.08, social_intensity)
		var reaction := _player_action_reaction_for_candidate(candidate, action_type, emotion, confirmed, index, message)
		var emotion_intensity: float = maxf(0.2, (0.52 - float(index) * 0.06 if not confirmed else 0.88 - float(index) * 0.1) * (0.84 + bias * 0.48))
		candidate.trigger_emotion_wave(reaction, source, 0.82 + float(index) * 0.06, emotion_intensity)
		if index <= 2:
			profession_seeds.append({
				"view": candidate,
				"emotion": reaction,
				"social_role": social_role,
				"intensity": emotion_intensity
			})
	_apply_profession_chain_reaction(profession_seeds, source, current_district, excluded_ids)


func _apply_profession_chain_reaction(seed_entries: Array, source: Vector2, district: String, excluded_ids: Array) -> void:
	return


func _profession_chain_social_role(seed, candidate, base_role: String, index: int, total_slots: int) -> String:
	var prop: String = seed.get_prop()
	var tier: String = _profession_chain_tier(index, total_slots)
	if prop == "paper":
		if tier == "inner":
			return "bystand"
		return "glance" if tier == "mid" else "yield"
	if prop == "tool":
		if tier == "inner":
			return "listener"
		return "slowpass" if tier == "mid" else "disperse"
	if prop == "ledger":
		return "listener" if tier != "edge" else "yield"
	if prop == "coin":
		if tier == "inner":
			return "interject"
		return "glance" if tier == "mid" else "disperse"
	if base_role == "speaker":
		return "listener" if tier != "edge" else "yield"
	if base_role == "slowpass":
		return "slowpass" if tier != "edge" else "disperse"
	return "glance" if tier != "edge" else "yield"


func _profession_chain_emotion(seed, candidate, base_emotion: String, index: int) -> String:
	var prop: String = seed.get_prop()
	if prop == "paper":
		return "puzzled" if index > 0 else base_emotion
	if prop == "tool":
		return "scoff" if base_emotion == "scoff" else "hurry" if index == 0 else "startled"
	if prop == "coin":
		return "startled" if index == 0 else "puzzled"
	if prop == "ledger":
		return "puzzled"
	if base_emotion == "hurry" and index > 0:
		return "startled"
	if base_emotion == "startled" and index > 0:
		return "puzzled"
	return base_emotion


func _profession_chain_tier(index: int, total_slots: int) -> String:
	if index == 0:
		return "inner"
	if index >= max(total_slots - 1, 1):
		return "edge"
	return "mid"


func _profession_chain_intensity_scale(tier: String) -> float:
	match tier:
		"inner":
			return 0.78
		"mid":
			return 0.62
		"edge":
			return 0.46
	return 0.56


func _profession_chain_social_duration(tier: String, index: int) -> float:
	match tier:
		"inner":
			return 1.04 + float(index) * 0.04
		"mid":
			return 0.92 + float(index) * 0.03
		"edge":
			return 0.76 + float(index) * 0.02
	return 0.84


func _profession_chain_linger_duration(tier: String, index: int) -> float:
	match tier:
		"inner":
			return 1.18 + float(index) * 0.06
		"mid":
			return 0.98 + float(index) * 0.05
		"edge":
			return 0.72 + float(index) * 0.04
	return 0.86


func _profession_chain_linger_offset(seed, candidate, index: int, chain_limit: int) -> Vector2:
	var prop: String = seed.get_prop()
	var tier: String = _profession_chain_tier(index, chain_limit)
	var base_angle: float = (seed.position - candidate.position).angle()
	var radius: float = 20.0 + float(index) * 8.0
	if prop == "paper":
		radius = 16.0 + float(index) * 7.0
	elif prop == "tool":
		radius = 26.0 + float(index) * 10.0
	elif prop == "coin":
		radius = 22.0 + float(index) * 8.0
	match tier:
		"inner":
			radius *= 0.72
		"mid":
			radius *= 0.98
		"edge":
			radius *= 1.24
	var angle_step: float = TAU / float(max(chain_limit + 1, 3))
	var angle: float = base_angle + angle_step * float(index + 1) - angle_step * 0.5
	if prop == "paper":
		angle = base_angle + lerpf(-0.6, 0.6, float(index) / float(max(chain_limit - 1, 1)))
	elif prop == "tool":
		angle += 0.2
	if tier == "edge":
		angle += 0.34
	return Vector2(cos(angle), sin(angle)) * radius


func _profession_seed_linger_offset(seed, source: Vector2, follower_count: int) -> Vector2:
	var prop: String = seed.get_prop()
	var direction: Vector2 = (seed.position - source).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.LEFT
	var radius: float = 10.0
	if prop == "paper":
		radius = 6.0
	elif prop == "tool":
		radius = 12.0
	elif prop == "coin":
		radius = 9.0
	return direction * radius + Vector2(0, min(float(follower_count), 3.0) * 2.0)


func _player_action_reaction_bias(candidate: NPCView, action_type: String, confirmed: bool) -> float:
	var bias := 0.2
	var role := candidate.get_role()
	var district := candidate.get_district()
	var activity := candidate.get_activity()
	var prop := candidate.get_prop()
	match action_type:
		"buy_stock", "sell_stock":
			if district == "交易所":
				bias += 0.55
			if role in ["投机者", "银行经理", "代理人", "记者"]:
				bias += 0.46
			if prop in ["coin", "ledger", "paper"]:
				bias += 0.18
		"buy_goods", "sell_goods":
			if district in ["贫民街", "港口"]:
				bias += 0.34
			if role in ["店主", "工人", "临时工"]:
				bias += 0.24
			if activity in ["working", "commuting"]:
				bias += 0.08
		"work":
			if district == "工厂区":
				bias += 0.44
			if role in ["工人", "临时工", "工会领袖"]:
				bias += 0.5
			if prop in ["tool", "megaphone"]:
				bias += 0.2
		"accept_task", "claim_task":
			if role in ["记者", "代理人", "店主"]:
				bias += 0.28
			if prop in ["paper", "ledger"]:
				bias += 0.14
		"end_day":
			if district == "工厂区":
				bias += 0.48
			elif district == "交易所":
				bias += 0.24
			if role in ["工人", "临时工", "工会领袖", "老板"]:
				bias += 0.32
			if activity in ["working", "commuting", "returning"]:
				bias += 0.22
		"gather_info":
			if role in ["记者", "代理人", "投机者"]:
				bias += 0.34
			if prop == "paper":
				bias += 0.16
	if confirmed:
		bias += 0.12
	return bias


func _player_action_social_role(candidate: NPCView, action_type: String, confirmed: bool, index: int) -> String:
	var role := candidate.get_role()
	var district := candidate.get_district()
	match action_type:
		"buy_stock", "sell_stock":
			if role in ["投机者", "银行经理", "代理人"] and index <= 1:
				return "listener" if confirmed else "glance"
			if district == "交易所" and index <= 2:
				return "bystand" if confirmed else "glance"
		"work":
			if role == "工会领袖" and confirmed:
				return "interject"
			if role in ["工人", "临时工"] and index <= 1:
				return "listener"
		"claim_task":
			if role in ["记者", "代理人"] and confirmed:
				return "bystand"
		"end_day":
			if role in ["工人", "临时工"] and confirmed:
				return "slowpass"
			if role == "老板" and confirmed:
				return "yield"
	if confirmed:
		if action_type == "end_day":
			return "slowpass" if index > 1 else "glance"
		if action_type == "claim_task":
			return "bystand" if index == 0 else "glance"
		if action_type == "buy_stock" or action_type == "sell_stock":
			return "listener" if index == 0 else "glance"
	return "glance"


func _player_action_reaction_for_candidate(candidate: NPCView, action_type: String, base_emotion: String, confirmed: bool, index: int, message: String) -> String:
	var reaction := base_emotion
	var role := candidate.get_role()
	var district := candidate.get_district()
	if confirmed:
		if base_emotion == "hurry" and index >= 2:
			reaction = "startled"
		elif base_emotion == "startled" and index >= 3:
			reaction = "puzzled"
		elif base_emotion == "scoff" and index == 0 and action_type == "claim_task":
			reaction = "startled"
	match action_type:
		"buy_stock", "sell_stock":
			if role in ["投机者", "银行经理"] and confirmed:
				return "startled" if action_type == "buy_stock" else "puzzled"
			if role == "记者":
				return "puzzled"
		"work":
			if role in ["工人", "临时工"]:
				return "scoff" if confirmed else "puzzled"
			if role == "工会领袖":
				return "startled" if confirmed else "puzzled"
		"claim_task":
			if role in ["记者", "代理人"] and confirmed:
				return "startled"
			if role == "店主":
				return "puzzled"
		"end_day":
			if district == "工厂区":
				return "hurry"
			if role == "老板":
				return "scoff" if message.contains("完成") else "puzzled"
	return reaction


func _maybe_trigger_news_emotion_wave(news_items: Array, district_name: String) -> void:
	var current_titles := _news_titles(news_items)
	if current_titles == last_news_titles:
		return
	if not last_news_titles.is_empty():
		var wave := _news_emotion_wave_payload(news_items, district_name)
		if not wave.is_empty():
			_trigger_news_emotion_wave(
				str(wave.get("emotion", "")),
				str(wave.get("district", district_name)),
				str(wave.get("scope", "district"))
			)
	last_news_titles = current_titles


func _news_titles(news_items: Array) -> Array[String]:
	var titles: Array[String] = []
	for item in news_items.slice(0, min(4, news_items.size())):
		titles.append(str(item.get("title", "")))
	return titles


func _news_emotion_wave_payload(news_items: Array, fallback_district: String) -> Dictionary:
	if news_items.is_empty():
		return {}
	var latest: Dictionary = news_items[0]
	return {
		"emotion": _news_emotion_for_item(latest),
		"district": _news_district_for_item(latest, fallback_district),
		"scope": str(latest.get("scope", "district"))
	}


func _news_emotion_for_item(item: Dictionary) -> String:
	var title := str(item.get("title", ""))
	var body := str(item.get("body", ""))
	var tone := str(item.get("tone", ""))
	var tags_text := ""
	for tag in item.get("tags", []):
		tags_text += " " + str(tag)
	var combined := "%s %s %s" % [title, body, tags_text]
	if combined.contains("恐慌") or combined.contains("挤兑") or combined.contains("拖") or combined.contains("断") or combined.contains("坏消息") or combined.contains("砍"):
		return "hurry"
	if combined.contains("抢购") or combined.contains("盘先动") or combined.contains("暴涨") or combined.contains("告急") or combined.contains("先动了手"):
		return "startled"
	if combined.contains("压消息") or combined.contains("机构") or combined.contains("风声") or combined.contains("传进") or tone == "cold":
		return "puzzled"
	if combined.contains("台阶") or combined.contains("稳") or combined.contains("休整"):
		return "scoff"
	return "puzzled"


func _news_district_for_item(item: Dictionary, fallback_district: String) -> String:
	var direct_district := str(item.get("district", ""))
	if not direct_district.is_empty():
		return direct_district
	for tag in item.get("tags", []):
		var tag_text := str(tag)
		if DISTRICT_RECTS.has(tag_text):
			return tag_text
	var combined := "%s %s" % [str(item.get("title", "")), str(item.get("body", ""))]
	for district_name in DISTRICT_RECTS.keys():
		if combined.contains(str(district_name)):
			return str(district_name)
	return fallback_district


func _trigger_news_emotion_wave(emotion: String, target_district: String, scope: String) -> void:
	if interior_mode or emotion.is_empty():
		return
	var current_district := _current_district_for_position(player.position)
	if scope != "city" and not target_district.is_empty() and target_district != current_district:
		return
	var candidates: Array = []
	for npc_id in npc_views.keys():
		var candidate: NPCView = npc_views[npc_id]
		if scope != "city" and candidate.get_district() != current_district:
			continue
		if scope == "city" and candidate.get_district() != current_district:
			continue
		var distance := candidate.position.distance_to(player.position)
		if distance > 320.0:
			continue
		candidates.append({"view": candidate, "distance": distance})
	if candidates.is_empty():
		return
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("distance", 99999.0)) < float(b.get("distance", 99999.0))
	)
	for index in range(min(5, candidates.size())):
		var candidate = candidates[index].get("view", null)
		if candidate == null:
			continue
		var reaction := emotion
		if emotion == "hurry" and index >= 2:
			reaction = "startled"
		elif emotion == "startled" and index >= 2:
			reaction = "puzzled"
		candidate.trigger_emotion_wave(reaction, player.position, 0.86 + float(index) * 0.08, 0.82 - float(index) * 0.11)


func _house_state_for_id(house_id: String) -> Dictionary:
	if house_id.is_empty():
		return {}
	var house_states: Dictionary = GameState.snapshot.get("house_states", {})
	if house_states.has(house_id):
		return house_states[house_id]
	return {}


func _to_world_position(pos: Vector2) -> Vector2:
	return pos * WORLD_VISUAL_SCALE


func _coerce_npc_backend_position(pos: Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, WORLD_RECT.position.x + 6.0, WORLD_RECT.end.x - 6.0),
		clampf(pos.y, WORLD_RECT.position.y + 6.0, WORLD_RECT.end.y - 6.0)
	)


func _scaled_district_rects() -> Dictionary:
	var scaled: Dictionary = {}
	for district_name in DISTRICT_RECTS.keys():
		var rect: Rect2 = DISTRICT_RECTS[district_name]
		scaled[district_name] = Rect2(rect.position * WORLD_VISUAL_SCALE, rect.size * WORLD_VISUAL_SCALE)
	return scaled


func _set_inspection_mode(enabled: bool) -> void:
	inspection_mode = enabled
	_apply_visibility_modes()
	inspect_badge.visible = inspection_mode
	if inspection_mode:
		GameState.add_toast("查看模式已开启：已隐藏遮挡与大面板。")
	else:
		GameState.add_toast("查看模式已关闭：恢复正常界面。")


func _set_ledger_ui_visible(enabled: bool) -> void:
	ledger_ui_visible = enabled
	if enabled:
		_open_interactable_actions()
	_apply_visibility_modes()
	if ledger_ui_visible:
		GameState.add_toast("账本界面已展开。")
	else:
		GameState.add_toast("账本界面已收起。")


func _apply_visibility_modes() -> void:
	backdrop.visible = not interior_mode
	ambient.visible = false
	interactable_layer.visible = not interior_mode
	npc_layer.visible = not interior_mode
	player.visible = not interior_mode
	top_overlay.visible = not inspection_mode and not interior_mode
	foreground.visible = false
	backdrop.set_process(not interior_mode)
	ambient.set_process(false)
	foreground.set_process(false)
	var ui_panels_visible := ledger_ui_visible and not inspection_mode
	var compact_visible := not ledger_ui_visible and not inspection_mode
	for node in optional_ui_nodes:
		if is_instance_valid(node):
			node.visible = ui_panels_visible
	for node in compact_ui_nodes:
		if is_instance_valid(node):
			node.visible = compact_visible
	var exchange_visible := _exchange_terminal_active() and not inspection_mode
	for node in exchange_terminal_nodes:
		if is_instance_valid(node):
			node.visible = exchange_visible
	if is_instance_valid(minimap_panel_node):
		minimap_panel_node.visible = ui_panels_visible and not interior_mode
	if is_instance_valid(subtitle_panel_node):
		subtitle_panel_node.visible = not inspection_mode
	for node in world_overlay_nodes:
		if is_instance_valid(node):
			node.visible = false and not interior_mode
	hud_badge.visible = not ledger_ui_visible and not interior_mode


func _set_interior_mode(enabled: bool, house_data: Dictionary = {}) -> void:
	interior_mode = enabled
	current_house_data = house_data.duplicate(true)
	if interior_mode:
		last_auto_enter_msec = Time.get_ticks_msec()
		var resolved_house_state := _house_state_for_id(str(house_data.get("state_house_id", house_data.get("id", ""))))
		current_house_data["house_state"] = resolved_house_state
		house_interior.enter_house({
			"house_state": resolved_house_state,
			"id": str(house_data.get("id", "")),
			"state_house_id": str(house_data.get("state_house_id", house_data.get("id", ""))),
			"action_house_id": str(house_data.get("action_house_id", house_data.get("state_house_id", house_data.get("id", "")))),
			"title": str(house_data.get("title", "屋内")),
			"subtitle": str(house_data.get("subtitle", "床铺、厨房和储物箱都在里面。")),
			"district": str(house_data.get("district", "贫民街"))
		})
		house_interior.set_exchange_hud_state(last_snapshot.get("stock_exchange_view", {}))
		house_interior.set_active(true)
		world_camera.enabled = false
		player.set_movement_direction(Vector2.ZERO)
		GameState.add_toast("你推门进了 %s。" % str(house_data.get("title", "屋内")))
	else:
		last_auto_enter_msec = Time.get_ticks_msec()
		house_interior.set_active(false)
		world_camera.enabled = true
		current_interactable = null
		GameState.add_toast("你回到了街上。")
	_apply_visibility_modes()


func _current_house_action_payload() -> Dictionary:
	var payload: Dictionary = house_interior.get_current_house_payload()
	payload["room"] = "interior"
	return payload


func _chip_color(district_name: String, state: String, is_current: bool) -> Color:
	var color := Color("5e4633")
	match district_name:
		"贫民街":
			color = Color("69462f")
		"港口":
			color = Color("35576a")
		"工厂区":
			color = Color("564238")
		"交易所":
			color = Color("71583e")
	match state:
		"prosperous":
			color = color.lightened(0.12)
		"tense":
			color = color.darkened(0.08)
		"unrest":
			color = color.darkened(0.18)
		"declining":
			color = color.darkened(0.24)
	if is_current:
		color = color.lightened(0.1)
	return color


func _enqueue_toast(message: String) -> void:
	toast_queue.append(message)
	if toast_timer.is_stopped():
		_show_next_toast()


func _show_next_toast() -> void:
	if toast_queue.is_empty():
		toast_label.text = ""
		return
	toast_label.text = toast_queue.pop_front()
	toast_label.modulate = Color(1, 1, 1, 0)
	if is_instance_valid(toast_tween):
		toast_tween.kill()
	toast_tween = create_tween()
	toast_tween.tween_property(toast_label, "modulate", Color(1, 1, 1, 1), 0.18)
	toast_tween.tween_interval(2.7)
	toast_tween.tween_property(toast_label, "modulate", Color(1, 1, 1, 0), 0.35)
	toast_timer.start()


func _on_modal_requested(payload: Dictionary) -> void:
	var tone := str(payload.get("tone", "news"))
	modal_is_conversation = tone == "conversation"
	modal_title.text = _sanitize_visible_text(str(payload.get("title", "告示")), "告示")
	var modal_text := str(payload.get("body", ""))
	active_dialogue_context = {}
	modal_input.visible = false
	modal_send_button.visible = false
	modal_send_button.disabled = false
	modal_hint_label.visible = false
	modal_trade_title.visible = false
	modal_trade_label.visible = false
	modal_trade_scroll.visible = false
	modal_trade_buttons.visible = false
	for child in modal_trade_buttons.get_children():
		child.queue_free()
	var tone_color := Color("3a2819")
	if tone == "event":
		tone_color = Color("6b2f23")
	elif tone == "conversation":
		tone_color = Color("315748")
		var dialogue_context: Dictionary = payload.get("dialogue", {})
		if dialogue_context.is_empty():
			dialogue_context = GameState.snapshot.get("last_dialogue", {})
		if not dialogue_context.is_empty():
			modal_text = str(dialogue_context.get("render_body", dialogue_context.get("body", modal_text)))
		if not dialogue_context.is_empty():
			active_dialogue_context = {
				"npc_id": str(dialogue_context.get("npc_id", "")),
				"district": str(dialogue_context.get("district", _current_district_for_position(player.position if not interior_mode else house_interior.get_player_position()))),
				"topic_id": str(dialogue_context.get("topic_id", "")),
				"approach": str(dialogue_context.get("approach", "cautious")),
				"intent": str(dialogue_context.get("intent", "继续追问")),
				"npc_name": str(dialogue_context.get("npc_name", "")),
				"trade_quotes": dialogue_context.get("trade_quotes", [])
			}
			modal_input.visible = true
			modal_send_button.visible = true
			modal_hint_label.visible = true
			_refresh_modal_trade_panel(dialogue_context)
			modal_input.grab_focus()
	elif tone == "probe":
		tone_color = Color("5b4630")
	modal_body.text = _sanitize_visible_text(modal_text, "城里刚有一阵新风声。")
	modal_title.add_theme_color_override("font_color", tone_color)
	_layout_modal_card()
	modal_overlay.visible = true
	modal_overlay.modulate = Color(1, 1, 1, 0)
	modal_card.scale = Vector2(0.94, 0.94)
	if is_instance_valid(modal_tween):
		modal_tween.kill()
	modal_tween = create_tween()
	modal_tween.set_parallel(true)
	modal_tween.tween_property(modal_overlay, "modulate", Color(1, 1, 1, 1), 0.18)
	modal_tween.tween_property(modal_card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _close_modal() -> void:
	if not modal_overlay.visible:
		return
	if is_instance_valid(modal_tween):
		modal_tween.kill()
	modal_tween = create_tween()
	modal_tween.set_parallel(true)
	modal_tween.tween_property(modal_overlay, "modulate", Color(1, 1, 1, 0), 0.14)
	modal_tween.tween_property(modal_card, "scale", Vector2(0.96, 0.96), 0.14)
	modal_tween.finished.connect(func() -> void:
		modal_overlay.visible = false
	)
	active_dialogue_context = {}
	modal_is_conversation = false
	pending_dialogue_request = {}
	modal_input.text = ""
	modal_input.visible = false
	modal_send_button.visible = false
	modal_hint_label.visible = false
	modal_trade_title.visible = false
	modal_trade_label.visible = false
	modal_trade_scroll.visible = false
	modal_trade_buttons.visible = false
	for child in modal_trade_buttons.get_children():
		child.queue_free()


func _submit_modal_player_talk() -> void:
	var player_input_shell := modal_input.text.strip_edges()
	if not player_input_shell.is_empty():
		var dialogue_context_shell := active_dialogue_context.duplicate(true)
		if str(dialogue_context_shell.get("npc_id", "")).is_empty():
			var last_dialogue_shell: Dictionary = GameState.snapshot.get("last_dialogue", {})
			if not last_dialogue_shell.is_empty():
				dialogue_context_shell = {
					"npc_id": str(last_dialogue_shell.get("npc_id", "")),
					"district": str(last_dialogue_shell.get("district", _current_district_for_position(player.position))),
					"topic_id": str(last_dialogue_shell.get("topic_id", "")),
					"approach": str(last_dialogue_shell.get("approach", "cautious")),
					"intent": "继续追问",
					"npc_name": str(last_dialogue_shell.get("npc_name", "")),
					"trade_quotes": last_dialogue_shell.get("trade_quotes", []),
				}
		if str(dialogue_context_shell.get("npc_id", "")).is_empty():
			GameState.add_toast("当前没有可继续追问的对象。")
			return
		active_dialogue_context = dialogue_context_shell
		pending_dialogue_request = active_dialogue_context.duplicate(true)
		pending_dialogue_request["player_input"] = player_input_shell
		pending_dialogue_request["started_msec"] = Time.get_ticks_msec()
		pending_dialogue_request["retry_count"] = 0
		modal_send_button.disabled = true
		status_label.text = "对方正在组织说法……"
		var live_scene_shell := _build_scene_observation_payload(false)
		ApiClient.post_json("/npc/player_talk", {
			"npc_id": str(dialogue_context_shell.get("npc_id", "")),
			"district": str(dialogue_context_shell.get("district", _current_district_for_position(player.position))),
			"topic_id": str(dialogue_context_shell.get("topic_id", "")),
			"approach": str(dialogue_context_shell.get("approach", "cautious")),
			"intent": str(active_dialogue_context.get("intent", "继续追问")),
			"player_input": player_input_shell,
			"player_position": live_scene_shell.get("player_position", {}),
			"screenshot_b64": "",
			"scene_context": live_scene_shell.get("scene_context", {})
		}, "player_talk")
		modal_input.text = ""
		return
	var player_input := modal_input.text.strip_edges()
	if player_input.is_empty():
		return
	var dialogue_context := active_dialogue_context.duplicate(true)
	if str(dialogue_context.get("npc_id", "")).is_empty():
		var last_dialogue: Dictionary = GameState.snapshot.get("last_dialogue", {})
		if not last_dialogue.is_empty():
			dialogue_context = {
				"npc_id": str(last_dialogue.get("npc_id", "")),
				"district": str(last_dialogue.get("district", _current_district_for_position(player.position))),
				"topic_id": str(last_dialogue.get("topic_id", "")),
				"approach": str(last_dialogue.get("approach", "cautious")),
				"intent": "继续追问",
				"npc_name": str(last_dialogue.get("npc_name", "")),
				"trade_quotes": last_dialogue.get("trade_quotes", [])
			}
	if str(dialogue_context.get("npc_id", "")).is_empty():
		GameState.add_toast("当前没有可继续追问的对象。")
		return
	if false and str(dialogue_context.get("npc_id", "")).is_empty():
		var nearby_npcs := _get_nearby_npcs(1)
		if not nearby_npcs.is_empty():
			dialogue_context = {
				"npc_id": str(nearby_npcs[0].get("id", "")),
				"district": _current_district_for_position(player.position),
				"topic_id": "",
				"approach": "cautious",
				"intent": "继续追问",
				"npc_name": str(nearby_npcs[0].get("name", "附近角色")),
				"trade_quotes": _fallback_trade_quotes(_npc_card_for_id(str(nearby_npcs[0].get("id", ""))))
			}
	if str(dialogue_context.get("npc_id", "")).is_empty():
		GameState.add_toast("附近没有可继续追问的角色。")
		return
	active_dialogue_context = dialogue_context
	pending_dialogue_request = active_dialogue_context.duplicate(true)
	pending_dialogue_request["player_input"] = player_input
	pending_dialogue_request["started_msec"] = Time.get_ticks_msec()
	pending_dialogue_request["retry_count"] = 0
	modal_send_button.disabled = true
	status_label.text = "对方正在整理说法……"
	var live_scene := _build_scene_observation_payload(false)
	ApiClient.post_json("/npc/player_talk", {
		"npc_id": str(dialogue_context.get("npc_id", "")),
		"district": str(dialogue_context.get("district", _current_district_for_position(player.position))),
		"topic_id": str(dialogue_context.get("topic_id", "")),
		"approach": str(dialogue_context.get("approach", "cautious")),
		"intent": str(active_dialogue_context.get("intent", "继续追问")),
		"player_input": player_input,
		"player_position": live_scene.get("player_position", {}),
		"screenshot_b64": "",
		"scene_context": live_scene.get("scene_context", {})
	}, "player_talk")
	modal_input.text = ""


func _refresh_modal_trade_panel(dialogue_context: Dictionary) -> void:
	var trade_payload := _modal_trade_payload(dialogue_context)
	if trade_payload.is_empty():
		modal_trade_title.visible = false
		modal_trade_label.visible = false
		modal_trade_scroll.visible = false
		modal_trade_buttons.visible = false
		for child in modal_trade_buttons.get_children():
			child.queue_free()
		return
	modal_trade_title.visible = true
	modal_trade_label.visible = true
	modal_trade_scroll.visible = true
	modal_trade_buttons.visible = true
	modal_trade_title.text = "和 %s 当面交易" % str(trade_payload.get("npc_name", "对方"))
	modal_trade_label.text = str(trade_payload.get("summary", ""))
	for child in modal_trade_buttons.get_children():
		child.queue_free()
	for quote in trade_payload.get("quotes", []):
		var action_button := Button.new()
		action_button.text = str(quote.get("button", "交易"))
		_style_button(action_button, Color("6c4a2a"), Color("8a6037"), Color("4f3520"))
		var action_type := str(quote.get("action_type", ""))
		action_button.disabled = action_type.is_empty()
		action_button.pressed.connect(func() -> void:
			_submit_modal_trade(quote)
		)
		modal_trade_buttons.add_child(action_button)


func _modal_trade_payload_legacy(dialogue_context: Dictionary) -> Dictionary:
	var npc_id := str(dialogue_context.get("npc_id", ""))
	if npc_id.is_empty():
		return {}
	var npc_card := _npc_card_for_id(npc_id)
	var quotes: Array = dialogue_context.get("trade_quotes", [])
	var card_quotes: Array = npc_card.get("trade_quotes", [])
	if not card_quotes.is_empty():
		quotes = card_quotes
	if quotes.is_empty():
		var dialogue: Dictionary = GameState.snapshot.get("last_dialogue", {})
		if str(dialogue.get("npc_id", "")) == npc_id:
			quotes = dialogue.get("trade_quotes", [])
	if quotes.is_empty() and not npc_card.is_empty():
		quotes = _fallback_trade_quotes(npc_card)
	if quotes.is_empty():
		return {}
	var quote_lines: Array[String] = []
	for quote in quotes:
		quote_lines.append("• %s" % str(quote.get("description", "")))
	return {
		"npc_name": str(dialogue_context.get("npc_name", npc_card.get("name", "对方"))),
		"summary": "[b]身份[/b] %s · [b]态度[/b] %s\n[b]现金[/b] %s 铜币 · [b]库存[/b] %s\n[b]消息生意[/b] %s\n%s" % [
			_npc_display_role(npc_card),
			str(npc_card.get("relation_status", "观望")),
			int(npc_card.get("cash", 0)),
			str(npc_card.get("inventory_summary", "没有报出库存")),
			"可卖，眼下开价 %s 铜币" % int(npc_card.get("intel_price", 0)) if bool(npc_card.get("can_sell_info", false)) else "暂时不肯直接卖",
			"\n".join(quote_lines),
		],
		"quotes": quotes,
	}


func _modal_trade_payload(dialogue_context: Dictionary) -> Dictionary:
	var npc_id := str(dialogue_context.get("npc_id", ""))
	if npc_id.is_empty():
		return {}
	var npc_card := _npc_card_for_id(npc_id)
	var quotes: Array = dialogue_context.get("trade_quotes", [])
	var card_quotes: Array = npc_card.get("trade_quotes", [])
	if not card_quotes.is_empty():
		quotes = card_quotes
	if quotes.is_empty():
		var dialogue: Dictionary = GameState.snapshot.get("last_dialogue", {})
		if str(dialogue.get("npc_id", "")) == npc_id:
			quotes = dialogue.get("trade_quotes", [])
	if quotes.is_empty() and not npc_card.is_empty():
		quotes = _fallback_trade_quotes(npc_card)
	if quotes.is_empty():
		return {}
	var quote_lines: Array[String] = []
	for quote in quotes:
		quote_lines.append("• %s" % str(quote.get("description", "")))
	var relation_status := str(npc_card.get("relation_status", "观望"))
	var speech_register := str(npc_card.get("speech_register", "平视你"))
	var intel_line := "暂时不肯直接卖"
	if bool(npc_card.get("can_sell_info", false)):
		intel_line = "可卖，眼下开价 %s 铜币" % int(npc_card.get("intel_price", 0))
	var summary_text := "[b]身份[/b] %s · [b]态度[/b] %s · [b]口风[/b] %s\n[b]现金[/b] %s 铜币 · [b]库存[/b] %s\n[b]消息生意[/b] %s\n%s" % [
		_npc_display_role(npc_card),
		relation_status,
		speech_register,
		int(npc_card.get("cash", 0)),
		str(npc_card.get("inventory_summary", "没有报出库存")),
		intel_line,
		"\n".join(quote_lines),
	]
	return {
		"npc_name": str(dialogue_context.get("npc_name", npc_card.get("name", "对方"))),
		"summary": summary_text,
		"quotes": quotes,
	}


func _fallback_trade_quotes(npc_card: Dictionary) -> Array:
	var ready_quotes: Array = npc_card.get("trade_quotes", [])
	if not ready_quotes.is_empty():
		return ready_quotes
	var quotes: Array = []
	var goods_rows: Array = GameState.snapshot.get("goods", [])
	for spec in [
		{"action": "buy_goods", "good": "面包", "qty": 1, "prefix": "买"},
		{"action": "buy_goods", "good": "煤", "qty": 1, "prefix": "买"},
		{"action": "sell_goods", "good": "罐头", "qty": 1, "prefix": "卖"},
	]:
		var good_name := str(spec.get("good", ""))
		var good_row := _snapshot_good_row(goods_rows, good_name)
		if good_row.is_empty():
			continue
		var unit_price := int(good_row.get("current_price", 0))
		var quoted_price: int = max(1, unit_price + int(round(float(npc_card.get("economic_pressure", 0.0)) * 4.0)))
		var action_type := str(spec.get("action", ""))
		var prefix := str(spec.get("prefix", ""))
		var button_text := "%s%s" % [prefix, good_name]
		var description := "%s%s x%s，眼下开价 %s 铜币。" % [prefix, good_name, int(spec.get("qty", 1)), quoted_price]
		if action_type == "sell_goods":
			button_text = "问%s价" % good_name
			description = "先问%s x%s 能卖到多少，眼下对方愿意按 %s 铜币收。" % [good_name, int(spec.get("qty", 1)), quoted_price]
		quotes.append({
			"action_type": action_type,
			"good_name": good_name,
			"quantity": int(spec.get("qty", 1)),
			"amount": quoted_price * int(spec.get("qty", 1)),
			"button": button_text,
			"description": description,
		})
	for amount in [1000, 10000, 100000]:
		quotes.append({
			"action_type": "gift_money",
			"amount": amount,
			"quantity": 1,
			"button": "送 %s 铜币" % amount,
			"description": "真给对方 %s 铜币，这笔钱会直接进他的口袋。" % amount,
		})
	if bool(npc_card.get("can_sell_info", false)):
		quotes.append({
			"action_type": "buy_intel",
			"amount": int(npc_card.get("intel_price", 0)),
			"quantity": 1,
			"topic_id": "",
			"button": "买消息 %s" % int(npc_card.get("intel_price", 0)),
			"description": "花 %s 铜币买一条消息。" % int(npc_card.get("intel_price", 0)),
		})
	return quotes


func _snapshot_good_row(goods_rows: Array, good_name: String) -> Dictionary:
	for row in goods_rows:
		if str(row.get("name", "")) == good_name:
			return row
	return {}


func _house_payload_for_node(node: InteractableView) -> Dictionary:
	var house_id := node.interaction_id
	var state_house_id := node.interaction_id
	var action_house_id := node.interaction_id
	if node.kind == "house" and node.interaction_id in ["exchange_house", "stock_exchange_6"]:
		house_id = "stock_exchange"
	return {
		"house_id": house_id,
		"house_title": node.title,
		"house_subtitle": node.subtitle,
		"state_house_id": state_house_id,
		"action_house_id": action_house_id
	}


func _submit_modal_trade(quote: Dictionary) -> void:
	if true:
		var npc_id_shell := str(active_dialogue_context.get("npc_id", ""))
		if npc_id_shell.is_empty():
			var last_dialogue_shell: Dictionary = GameState.snapshot.get("last_dialogue", {})
			npc_id_shell = str(last_dialogue_shell.get("npc_id", ""))
		if npc_id_shell.is_empty():
			GameState.add_toast("当前没有可交易的对象。")
			return
		var payload_shell: Dictionary = quote.duplicate(true)
		payload_shell["npc_id"] = npc_id_shell
		payload_shell.erase("button")
		payload_shell.erase("description")
		var action_type_shell := str(payload_shell.get("action_type", ""))
		_submit_interaction({
			"action_type": "trade_action",
			"trade_mode": action_type_shell,
			"district": _current_district_for_position(player.position if not interior_mode else house_interior.get_player_position()),
			"payload": payload_shell
		})
		return
	var npc_id := str(active_dialogue_context.get("npc_id", ""))
	if npc_id.is_empty():
		GameState.add_toast("当前没有可交易的对象。")
		return
	var payload: Dictionary = quote.duplicate(true)
	payload["npc_id"] = npc_id
	payload.erase("button")
	payload.erase("description")
	var action_type := str(payload.get("action_type", ""))
	_submit_interaction({
		"action_type": "trade_action",
		"trade_mode": action_type,
		"district": _current_district_for_position(player.position if not interior_mode else house_interior.get_player_position()),
		"payload": payload
	})


func _exchange_terminal_active() -> bool:
	return interior_mode and str(current_house_data.get("id", "")) in ["stock_exchange", "exchange_house", "stock_exchange_6"]


func _update_exchange_terminal(snapshot: Dictionary) -> void:
	if not is_instance_valid(exchange_terminal_panel):
		return
	if not _exchange_terminal_active():
		exchange_terminal_summary.text = ""
		exchange_terminal_tape.text = ""
		for child in exchange_terminal_actions.get_children():
			child.queue_free()
		return
	var exchange_view: Dictionary = snapshot.get("stock_exchange_view", {})
	var stocks: Array = exchange_view.get("stocks", [])
	var tape: Array = exchange_view.get("tape", [])
	var session_label := str(exchange_view.get("session_label", "08:00-18:00"))
	var clock_label := str(exchange_view.get("clock_label", "08:00"))
	var feedback := _sanitize_visible_text(str(exchange_view.get("feedback", "")), "")
	var market_open := bool(exchange_view.get("market_open", true))
	var account_tier: Dictionary = exchange_view.get("account_tier", {})
	var reputation: Dictionary = exchange_view.get("reputation", {})
	var shadow: Dictionary = exchange_view.get("shadow_reputation", {})
	var warnings: Array = exchange_view.get("warnings", [])
	var lines: Array[String] = []
	for stock in stocks:
		var stock_name := str(stock.get("display_name", stock.get("name", "")))
		var price := int(stock.get("current_price", 0))
		var held := int(stock.get("held", 0))
		var market_cap := int(stock.get("market_cap", 0))
		var change_amount := int(stock.get("change_amount", 0))
		var change_pct := float(stock.get("change_pct", 0.0)) * 100.0
		var trade_volume := int(stock.get("trade_volume", 0))
		var holders: Array = stock.get("major_holders", [])
		var holder_parts: Array[String] = []
		for holder in holders:
			holder_parts.append("%s:%s" % [str(holder.get("holder_name", "")), int(holder.get("shares", 0))])
		var change_color := "#d8b982"
		if change_pct > 0.01:
			change_color = "#d96d52"
		elif change_pct < -0.01:
			change_color = "#74b58a"
		lines.append("[b]%s[/b]  现价 %s  持仓 %s\n[color=%s]涨跌 %+d / %+.2f%%[/color]  总市值 %s  成交量 %s\n主力席位 %s" % [
			stock_name,
			price,
			held,
			change_color,
			change_amount,
			change_pct,
			market_cap,
			trade_volume,
			" / ".join(holder_parts) if not holder_parts.is_empty() else "暂无大户",
		])
	var status_color := "#74b58a" if market_open else "#d96d52"
	var status_line := "[color=%s]%s[/color]" % [status_color, "开市" if market_open else "休市"]
	if not feedback.is_empty():
		status_line += "  %s" % feedback
	var warning_lines: Array[String] = []
	for warning in warnings.slice(0, min(2, warnings.size())):
		warning_lines.append(" - %s" % str(warning))
	exchange_terminal_summary.text = "[b]账户[/b] %s  杠杆 %s  现金 %s  持仓总值 %s  总资产 %s\n[b]交易所状态[/b] %s  当前时间 %s  交易时段 %s\n[b]革命税[/b] 玩家累计 %s  全市场累计 %s  起义军武装等级 WL %s\n[b]声望[/b] FC %s / FB %s / SN %s\n[b]影子盘[/b] SUI %s / ST %s / 风险 %s / 警局 %s\n%s%s" % [
		str(account_tier.get("label", "青铜级")),
		str(account_tier.get("leverage", "1x-10x")),
		int(exchange_view.get("player_cash", 0)),
		int(exchange_view.get("player_holdings_value", 0)),
		int(exchange_view.get("player_total_wealth", 0)),
		status_line,
		clock_label,
		session_label,
		int(exchange_view.get("player_trading_fees", 0)),
		int(exchange_view.get("sam_tax_total", 0)),
		int(shadow.get("WL", 1)),
		int(reputation.get("FC", 10)),
		int(reputation.get("FB", 5)),
		int(reputation.get("SN", 20)),
		shadow.get("SUI", 15),
		shadow.get("ST", 1.0),
		str(exchange_view.get("market_risk", "缄默期")),
		str(shadow.get("police_side", "摇摆观望")),
		"\n".join(warning_lines) + "\n" if not warning_lines.is_empty() else "",
		"\n\n".join(lines),
	]
	var tape_lines: Array[String] = []
	for row in tape.slice(0, min(4, tape.size())):
		tape_lines.append("- %s" % _sanitize_visible_text(str(row.get("anonymous_label", "")), "刚才还没有新的成交。"))
	if tape_lines.is_empty():
		tape_lines.append("- 刚才还没有新的成交。")
	exchange_terminal_tape.text = "[b]最近成交[/b]\n%s" % "\n".join(tape_lines)
	for child in exchange_terminal_actions.get_children():
		child.queue_free()
	for stock in stocks:
		var stock_name := str(stock.get("name", ""))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var row_label := Label.new()
		row_label.text = str(stock.get("ticker", stock_name))
		row_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_label.add_theme_font_size_override("font_size", 16)
		row_label.add_theme_color_override("font_color", Color("f0dfbe"))
		row.add_child(row_label)
		for spec in [
			{"text": "买1", "mode": "buy_stock", "qty": 1, "base": Color("2f6f4f"), "hover": Color("3f8a60"), "press": Color("244f3a")},
			{"text": "卖1", "mode": "sell_stock", "qty": 1, "base": Color("6c4a2a"), "hover": Color("8a6037"), "press": Color("4f3520")},
			{"text": "买10", "mode": "buy_stock", "qty": 10, "base": Color("2f6f4f"), "hover": Color("3f8a60"), "press": Color("244f3a")},
			{"text": "卖10", "mode": "sell_stock", "qty": 10, "base": Color("6c4a2a"), "hover": Color("8a6037"), "press": Color("4f3520")},
		]:
			var button := Button.new()
			button.text = str(spec.get("text", "交易"))
			button.custom_minimum_size = Vector2(58, 32)
			_style_button(button, spec.get("base", Color("6c4a2a")), spec.get("hover", Color("8a6037")), spec.get("press", Color("4f3520")))
			button.pressed.connect(func() -> void:
				_submit_exchange_stock_trade(stock_name, str(spec.get("mode", "buy_stock")), int(spec.get("qty", 1)))
			)
			row.add_child(button)
		exchange_terminal_actions.add_child(row)


func _submit_exchange_stock_trade(stock_name: String, action_type: String, quantity: int) -> void:
	if stock_name.is_empty() or quantity <= 0:
		return
	_submit_interaction({
		"action_type": action_type,
		"district": _current_district_for_position(player.position if not interior_mode else house_interior.get_player_position()),
		"payload": {
			"stock_name": stock_name,
			"quantity": quantity,
		},
	})


func _on_guide_updated(steps: Array, current_index: int) -> void:
	var lines: Array[String] = []
	for index in range(steps.size()):
		var prefix := "[color=#2d6a4f]>>[/color]" if index == current_index else "[color=#7a6a50]-[/color]"
		lines.append("%s %s" % [prefix, steps[index]])
	guide_label.text = "\n".join(lines)
