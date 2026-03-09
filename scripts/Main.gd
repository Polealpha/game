extends Node2D

const PlayerView = preload("res://scripts/world/Player.gd")
const InteractableView = preload("res://scripts/world/Interactable.gd")
const NPCView = preload("res://scripts/world/NPCView.gd")
const WorldBackdrop = preload("res://scripts/world/WorldBackdrop.gd")
const WorldAmbient = preload("res://scripts/world/WorldAmbient.gd")
const WorldForeground = preload("res://scripts/world/WorldForeground.gd")
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
const NPC_AUTO_TALK_RADIUS := 96.0
const DIRECT_TALK_RADIUS := 54.0
const HOUSE_ENTRY_RADIUS := 30.0
const BACKEND_RETRY_MSEC := 5000
const BACKEND_HEALTHCHECK_MSEC := 1600

var player := PlayerView.new()
var world_tint := CanvasModulate.new()
var backdrop := WorldBackdrop.new()
var ambient := WorldAmbient.new()
var foreground := WorldForeground.new()
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
var camera_focus_offset := Vector2.ZERO
var backend_autostart_attempted := false
var backend_process_id := -1
var backend_service_ready := false
var backend_health_pending := false
var backend_last_start_msec := -60000
var backend_last_healthcheck_msec := -60000
var backend_error_streak := 0
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
var modal_card := PanelContainer.new()
var modal_input := LineEdit.new()
var modal_send_button := Button.new()
var modal_hint_label := Label.new()
var modal_trade_title := Label.new()
var modal_trade_label := RichTextLabel.new()
var modal_trade_buttons := HBoxContainer.new()
var compact_hud_label := RichTextLabel.new()
var market_flash_label := RichTextLabel.new()
var news_ticker_label := RichTextLabel.new()
var interaction_badge_label := Label.new()
var inspect_badge := Label.new()
var hud_badge := Label.new()
var minimap_panel_node: CanvasItem
var subtitle_panel_node: CanvasItem
var toast_tween: Tween
var modal_tween: Tween


func _ready() -> void:
	Engine.max_fps = 60
	add_child(world_tint)
	add_child(backdrop)
	add_child(ambient)
	add_child(world_actor_layer)
	world_actor_layer.y_sort_enabled = true
	world_actor_layer.add_child(interactable_layer)
	world_actor_layer.add_child(npc_layer)
	world_actor_layer.add_child(player)
	add_child(foreground)
	add_child(house_interior)
	add_child(world_camera)
	add_child(music_player)
	add_child(ui_layer)
	interactable_layer.y_sort_enabled = true
	npc_layer.y_sort_enabled = true
	interactable_layer.z_index = -2
	ui_layer.add_child(ui_root)
	backdrop.scale = Vector2.ONE * WORLD_VISUAL_SCALE
	ambient.scale = Vector2.ONE * WORLD_VISUAL_SCALE
	foreground.scale = Vector2.ONE * WORLD_VISUAL_SCALE
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
	ApiClient.request_failed.connect(_on_api_error)
	GameState.snapshot_updated.connect(_on_snapshot_updated)
	GameState.toast_added.connect(_enqueue_toast)
	UiRouter.modal_requested.connect(_on_modal_requested)
	UiRouter.guide_updated.connect(_on_guide_updated)

	poll_timer.wait_time = 1.0
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

	_attempt_service_autostart()
	_poll_world_state()


func _process(delta: float) -> void:
	_advance_visual_clock(delta)
	_advance_news_ticker(delta)
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
	modal_body.scroll_active = true
	modal_body.custom_minimum_size = Vector2(790, 270)
	modal_body.add_theme_color_override("default_color", Color("2d2014"))
	modal_box.add_child(modal_body)

	modal_hint_label.text = "直接输入一句话发给对面的角色，由大模型实时生成回应。"
	modal_hint_label.add_theme_font_size_override("font_size", 16)
	modal_hint_label.add_theme_color_override("font_color", Color("6a5137"))
	modal_box.add_child(modal_hint_label)

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


func _update_compact_hud(snapshot: Dictionary, district_name: String) -> void:
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
	if modal_overlay.visible or ledger_ui_visible or inspection_mode:
		npc_auto_talk_elapsed = 0.0
		return
	npc_auto_talk_elapsed += delta
	if npc_auto_talk_elapsed < NPC_AUTO_TALK_SECONDS:
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
		active_dialogue_context = {
			"npc_id": npc_id,
			"district": _current_district_for_position(player.position),
			"topic_id": "",
			"approach": "friendly",
			"intent": "主动搭话"
		}
		var live_scene := _build_scene_observation_payload(true)
		ApiClient.post_json("/npc/player_talk", {
			"npc_id": npc_id,
			"district": _current_district_for_position(player.position),
			"topic_id": "",
			"approach": "friendly",
			"intent": "主动搭话",
			"player_position": live_scene.get("player_position", {}),
			"screenshot_b64": str(live_scene.get("screenshot_b64", "")),
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
	player.position = Vector2(
		clampf(player.position.x + input_vector.x * PLAYER_SPEED * delta, 0.0, world_size.x),
		clampf(player.position.y + input_vector.y * PLAYER_SPEED * delta, 0.0, world_size.y)
	)


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
	if not _get_nearby_npcs(1, DIRECT_TALK_RADIUS * WORLD_VISUAL_SCALE).is_empty():
		for node in interactables:
			node.set_highlighted(false)
		current_interactable = null
		hint_label.text = "附近有人。按 E 直接搭话，H 账本，Tab 查看模式。"
		return
	var previous_interactable := current_interactable
	var nearest: InteractableView = null
	var best_distance := 99999.0
	for node in interactables:
		var distance := player.position.distance_to(node.position)
		var interaction_radius := 78.0 * WORLD_VISUAL_SCALE
		if node.kind == "house":
			interaction_radius = HOUSE_ENTRY_RADIUS * WORLD_VISUAL_SCALE
		node.set_focus_strength(clampf(1.0 - distance / (interaction_radius * 1.5), 0.0, 1.0))
		var is_target := distance < interaction_radius and distance < best_distance
		if is_target:
			best_distance = distance
			nearest = node
	for node in interactables:
		node.set_highlighted(node == nearest)
	current_interactable = nearest
	if ledger_ui_visible and previous_interactable != current_interactable:
		_open_interactable_actions()
	if current_interactable == null:
		var nearby_npcs := _get_nearby_npcs(2)
		if nearby_npcs.is_empty():
			hint_label.text = "四处走动。靠近摊位、告示板、交易席位或工牌后按 E 打开操作。F3 显示听觉圈，Tab 切换查看模式。"
		else:
			hint_label.text = "附近有人。按 E 可直接搭话，或继续走向摊位和告示板。F3 显示听觉圈，Tab 切换查看模式。"
	else:
		hint_label.text = "靠近 %s。按 E 进行操作。%s  H 开关账本界面，Tab 临时取消遮挡。" % [current_interactable.title, current_interactable.subtitle]


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
	_add_action_button("手动触发 AI 脉冲", {"action_type":"manual_pulse"})
	_add_action_button("测试 AI 连接", {"action_type":"probe_ai"})
	_add_action_button("重置世界到第一天", {"action_type":"reset_world"})


func _trigger_primary_interaction() -> void:
	var payload := _default_payload_for_current_context()
	if payload.is_empty():
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
	if nearby_npcs.is_empty():
		if current_interactable != null:
			return _default_payload_for_interactable(current_interactable)
		return {}
	var npc_id := str(nearby_npcs[0].get("id", ""))
	if npc_id.is_empty():
		if current_interactable != null:
			return _default_payload_for_interactable(current_interactable)
		return {}
	return {
		"action_type":"player_talk",
		"district": _current_district_for_position(player.position),
		"payload":{
			"npc_id": npc_id,
			"approach":"cautious",
			"intent":"街头搭话",
			"subregion_name": _current_subregion_for_position(player.position)
		}
	}


func _default_payload_for_interactable(node: InteractableView) -> Dictionary:
	match node.kind:
		"house":
			return {
				"action_type":"enter_house",
				"district": node.district,
				"payload":{
					"house_id": node.interaction_id,
					"house_title": node.title,
					"house_subtitle": node.subtitle
				}
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


func _add_context_actions(node: InteractableView) -> void:
	match node.kind:
		"house":
			_add_action_button("推门进屋", {
				"action_type":"enter_house",
				"district": node.district,
				"payload":{
					"house_id": node.interaction_id,
					"house_title": node.title,
					"house_subtitle": node.subtitle
				}
			})
		"work":
			_add_action_button("做一轮打工", {"action_type":"work", "district": node.district})
		"goods":
			for good_name in ["面包", "煤", "罐头"]:
				_add_action_button("买入 %s" % good_name, {"action_type":"buy_goods", "district": node.district, "payload":{"good_name":good_name, "quantity":1}})
				_add_action_button("卖出 %s" % good_name, {"action_type":"sell_goods", "district": node.district, "payload":{"good_name":good_name, "quantity":1}})
		"stocks":
			for stock_name in ["蓝潮航运", "黑石矿业", "晨报传媒"]:
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
		var npc_role := str(entry.get("role", "路人"))
		var card := _npc_card_for_id(npc_id)
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
		var live_scene := _build_scene_observation_payload(true)
		ApiClient.post_json("/npc/player_talk", {
			"npc_id": str(payload.get("payload", {}).get("npc_id", "")),
			"district": str(payload.get("district", "")),
			"topic_id": str(payload.get("payload", {}).get("topic_id", "")),
			"approach": str(payload.get("payload", {}).get("approach", "cautious")),
			"intent": str(payload.get("payload", {}).get("intent", "")),
			"player_position": live_scene.get("player_position", {}),
			"screenshot_b64": str(live_scene.get("screenshot_b64", "")),
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
		return current_interactable.position - player.position
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
		return current_interactable.position - player.position
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
	var now := Time.get_ticks_msec()
	if not backend_service_ready or now - backend_last_healthcheck_msec >= BACKEND_HEALTHCHECK_MSEC:
		_probe_backend_health()
		return
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
	var observation := _build_scene_observation_payload(true)
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
			if speaker.position.distance_to(listener.position) <= 110.0:
				_play_npc_conversation_beat(speaker, listener)
				var live_scene := _build_scene_observation_payload(true)
				ApiClient.post_json("/npc/conversation", {
					"speaker_id": speaker_id,
					"listener_id": listener_id,
					"trigger": "街头搭话",
					"current_district": str(live_scene.get("current_district", "")),
					"player_position": live_scene.get("player_position", {}),
					"screenshot_b64": str(live_scene.get("screenshot_b64", "")),
					"scene_context": live_scene.get("scene_context", {})
				}, "conversation")
				return


func _play_npc_conversation_beat(speaker, listener) -> void:
	var midpoint: Vector2 = (speaker.position + listener.position) * 0.5
	var bystander = _find_conversation_bystander(speaker.get_npc_id(), listener.get_npc_id(), midpoint, speaker.get_district())
	var ripple_npcs: Array = _find_conversation_ripple(speaker.get_npc_id(), listener.get_npc_id(), midpoint, speaker.get_district(), bystander)
	var pattern := randi() % 5
	match pattern:
		0:
			speaker.trigger_social_beat(listener.position, true, "speaker", 1.1, 1.0)
			listener.trigger_social_beat(speaker.position, false, "listener", 1.0, 0.95)
			if bystander != null:
				bystander.trigger_social_beat(midpoint, false, "bystand", 1.15, 0.72)
		1:
			speaker.trigger_social_beat(listener.position, true, "speaker", 0.95, 0.82)
			listener.trigger_social_beat(speaker.position, false, "interject", 0.72, 1.08)
			if bystander != null:
				bystander.trigger_social_beat(midpoint, false, "bystand", 0.92, 0.68)
		2:
			speaker.trigger_social_beat(listener.position, true, "pause", 0.62, 0.75)
			listener.trigger_social_beat(speaker.position, false, "interject", 0.76, 0.9)
			if bystander != null:
				bystander.trigger_social_beat(midpoint, false, "interject", 0.62, 0.76)
		3:
			speaker.trigger_social_beat(listener.position, true, "speaker", 0.92, 0.8)
			listener.trigger_social_beat(speaker.position, false, "yield", 0.86, 0.82)
			if bystander != null:
				bystander.trigger_social_beat(midpoint, false, "bystand", 0.95, 0.62)
		_:
			speaker.trigger_social_beat(listener.position, true, "disperse", 0.86, 0.74)
			listener.trigger_social_beat(speaker.position, false, "yield", 0.8, 0.72)
			if bystander != null:
				bystander.trigger_social_beat(midpoint, false, "dismiss", 0.82, 0.7)
	_apply_conversation_ripple(ripple_npcs, midpoint)
	_apply_conversation_emotion_wave(pattern, speaker, listener, bystander, ripple_npcs, midpoint)


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
	if tag == "player_talk":
		dialogue_payload = data.get("dialogue", {})
		if dialogue_payload.is_empty() and data.has("world_state"):
			dialogue_payload = data.get("world_state", {}).get("last_dialogue", {})
	if data.has("world_state"):
		GameState.apply_snapshot(data["world_state"])
	if tag == "player_talk":
		var dialogue: Dictionary = dialogue_payload
		modal_send_button.disabled = false
		if not dialogue.is_empty():
			dialogue["title"] = _sanitize_visible_text(str(dialogue.get("title", "")), "街头交谈")
			dialogue["body"] = _sanitize_visible_text(str(dialogue.get("body", "")), "对方沉默了一会，又看了你一眼。")
			_play_player_talk_feedback(dialogue)
			modal_send_button.disabled = false
			UiRouter.push_modal(
				str(dialogue.get("title", "街头交谈")),
				str(dialogue.get("body", "")),
				str(dialogue.get("tone", "conversation")),
				{"dialogue": dialogue}
			)
	elif tag == "probe_ai":
		UiRouter.push_modal("AI 连接测试", "[b]状态[/b]\n%s" % _sanitize_visible_text(str(data.get("message", "")), "连接已建立，正在等待下一轮脉冲。"), "probe")
	if data.has("message") and not str(data["message"]).is_empty():
		GameState.add_toast(_sanitize_visible_text(str(data["message"]), "城里刚有一阵新风声。"))
	elif tag == "world_state":
		status_label.text = "服务在线，正在等待下一轮耳语。"
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


func _on_api_error(tag: String, status_code: int, message: String) -> void:
	if not pending_player_reaction.is_empty() and str(pending_player_reaction.get("tag", "")) == tag:
		pending_player_reaction = {}
	if tag == "player_talk":
		modal_send_button.disabled = false
	status_label.text = "请求 %s 失败 (%s)" % [tag, status_code]
	GameState.add_toast("服务离线或未启动。先运行本地 Python 服务。")
	if not message.is_empty():
		news_label.text = "[color=#6f1d1b]%s[/color]" % message


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
	_update_stocks(snapshot.get("stocks", []), player_data.get("stock_holdings", {}))
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
	house_interior.update_house_state(_house_state_for_id(str(current_house_data.get("id", ""))))
	_refresh_npcs()
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


func _update_stocks(stocks: Array, holdings: Dictionary) -> void:
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


func _get_nearby_npcs(limit: int) -> Array:
	if interior_mode:
		return []
	var ranked: Array = []
	for view in npc_views.values():
		var distance := player.position.distance_to(view.position)
		if distance <= 126.0 * WORLD_VISUAL_SCALE:
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
	if seed_entries.is_empty():
		return
	var excluded: Dictionary = {}
	for npc_id in excluded_ids:
		excluded[str(npc_id)] = true
	for entry in seed_entries:
		var seed = entry.get("view", null)
		if seed == null:
			continue
		var seed_role: String = seed.get_role()
		var seed_prop: String = seed.get_prop()
		if seed_role.is_empty():
			continue
		var chain_candidates: Array = []
		for npc_id in npc_views.keys():
			if excluded.has(str(npc_id)):
				continue
			var candidate: NPCView = npc_views[npc_id]
			if candidate.get_district() != district:
				continue
			if candidate.get_role() != seed_role:
				continue
			if candidate == seed:
				continue
			var distance_to_seed := candidate.position.distance_to(seed.position)
			if distance_to_seed > 150.0:
				continue
			var score := distance_to_seed
			if not seed_prop.is_empty() and candidate.get_prop() == seed_prop:
				score -= 26.0
			if candidate.get_activity() == seed.get_activity():
				score -= 12.0
			chain_candidates.append({"view": candidate, "score": score, "distance": distance_to_seed})
		if chain_candidates.is_empty():
			continue
		chain_candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a.get("score", 99999.0)) < float(b.get("score", 99999.0))
		)
		var chain_limit := 2
		if seed_prop == "paper":
			chain_limit = 3
		var group_center: Vector2 = seed.position.lerp(source, 0.38)
		var applied_views: Array = []
		var total_slots: int = min(chain_limit, chain_candidates.size())
		for index in range(min(chain_limit, chain_candidates.size())):
			var candidate = chain_candidates[index].get("view", null)
			if candidate == null:
				continue
			excluded[str(candidate.get_npc_id())] = true
			applied_views.append(candidate)
			var chain_tier: String = _profession_chain_tier(index, total_slots)
			var chain_role := _profession_chain_social_role(seed, candidate, str(entry.get("social_role", "glance")), index, total_slots)
			var chain_emotion := _profession_chain_emotion(seed, candidate, str(entry.get("emotion", "puzzled")), index)
			var chain_intensity: float = maxf(0.24, float(entry.get("intensity", 0.5)) * _profession_chain_intensity_scale(chain_tier))
			candidate.set_observer_target(seed.position.lerp(source, 0.35), 0.34 + chain_intensity * 0.24)
			candidate.trigger_social_beat(
				seed.position,
				false,
				chain_role,
				_profession_chain_social_duration(chain_tier, index),
				maxf(0.22, chain_intensity * 0.9)
			)
			candidate.trigger_emotion_wave(chain_emotion, seed.position, 0.86 + float(index) * 0.06, chain_intensity)
			candidate.set_social_linger(
				group_center,
				_profession_chain_linger_offset(seed, candidate, index, total_slots),
				_profession_chain_linger_duration(chain_tier, index),
				chain_intensity
			)
		if not applied_views.is_empty():
			seed.set_social_linger(
				group_center,
				_profession_seed_linger_offset(seed, source, applied_views.size()),
				1.04,
				maxf(0.28, float(entry.get("intensity", 0.5)) * 0.82)
			)


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
	var clamped := Vector2(
		clampf(pos.x, WORLD_RECT.position.x + 6.0, WORLD_RECT.end.x - 6.0),
		clampf(pos.y, WORLD_RECT.position.y + 6.0, WORLD_RECT.end.y - 6.0)
	)
	if WorldLayout.is_walkable_point(clamped):
		return clamped
	var snapped := WorldLayout.snap_to_walkable(clamped)
	if clamped.distance_to(snapped) <= 24.0:
		return snapped
	return clamped


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
	ambient.visible = not interior_mode
	interactable_layer.visible = not interior_mode
	npc_layer.visible = not interior_mode
	player.visible = not interior_mode
	foreground.visible = not inspection_mode and not interior_mode
	backdrop.set_process(not interior_mode)
	ambient.set_process(not interior_mode)
	foreground.set_process(not inspection_mode and not interior_mode)
	var ui_panels_visible := ledger_ui_visible and not inspection_mode
	var compact_visible := not ledger_ui_visible and not inspection_mode
	for node in optional_ui_nodes:
		if is_instance_valid(node):
			node.visible = ui_panels_visible
	for node in compact_ui_nodes:
		if is_instance_valid(node):
			node.visible = compact_visible
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
		var resolved_house_state := _house_state_for_id(str(house_data.get("id", "")))
		current_house_data["house_state"] = resolved_house_state
		house_interior.enter_house({
			"house_state": resolved_house_state,
			"id": str(house_data.get("id", "")),
			"title": str(house_data.get("title", "屋内")),
			"subtitle": str(house_data.get("subtitle", "床铺、厨房和储物箱都在里面。")),
			"district": str(house_data.get("district", "贫民街"))
		})
		house_interior.set_active(true)
		world_camera.enabled = false
		player.set_movement_direction(Vector2.ZERO)
		GameState.add_toast("你推门进了 %s。" % str(house_data.get("title", "屋内")))
	else:
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
	modal_title.text = _sanitize_visible_text(str(payload.get("title", "告示")), "告示")
	modal_body.text = _sanitize_visible_text(str(payload.get("body", "")), "城里刚有一阵新风声。")
	active_dialogue_context = {}
	modal_input.visible = false
	modal_send_button.visible = false
	modal_send_button.disabled = false
	modal_hint_label.visible = false
	var tone_color := Color("3a2819")
	if tone == "event":
		tone_color = Color("6b2f23")
	elif tone == "conversation":
		tone_color = Color("315748")
		var dialogue_context: Dictionary = payload.get("dialogue", {})
		if dialogue_context.is_empty():
			dialogue_context = GameState.snapshot.get("last_dialogue", {})
		if not dialogue_context.is_empty():
			active_dialogue_context = {
				"npc_id": str(dialogue_context.get("npc_id", "")),
				"district": _current_district_for_position(player.position if not interior_mode else house_interior.get_player_position()),
				"topic_id": str(dialogue_context.get("topic_id", "")),
				"approach": str(dialogue_context.get("approach", "cautious")),
				"intent": "继续追问"
			}
			modal_input.visible = true
			modal_send_button.visible = true
			modal_hint_label.visible = true
			modal_input.grab_focus()
	elif tone == "probe":
		tone_color = Color("5b4630")
	modal_title.add_theme_color_override("font_color", tone_color)
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
	modal_input.text = ""
	modal_input.visible = false
	modal_send_button.visible = false
	modal_hint_label.visible = false


func _submit_modal_player_talk() -> void:
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
				"intent": "继续追问"
			}
	if str(dialogue_context.get("npc_id", "")).is_empty():
		var nearby_npcs := _get_nearby_npcs(1)
		if not nearby_npcs.is_empty():
			dialogue_context = {
				"npc_id": str(nearby_npcs[0].get("id", "")),
				"district": _current_district_for_position(player.position),
				"topic_id": "",
				"approach": "cautious",
				"intent": "继续追问"
			}
	if str(dialogue_context.get("npc_id", "")).is_empty():
		GameState.add_toast("附近没有可继续追问的角色。")
		return
	active_dialogue_context = dialogue_context
	modal_send_button.disabled = true
	var live_scene := _build_scene_observation_payload(true)
	ApiClient.post_json("/npc/player_talk", {
		"npc_id": str(dialogue_context.get("npc_id", "")),
		"district": str(dialogue_context.get("district", _current_district_for_position(player.position))),
		"topic_id": str(dialogue_context.get("topic_id", "")),
		"approach": str(dialogue_context.get("approach", "cautious")),
		"intent": str(active_dialogue_context.get("intent", "继续追问")),
		"player_input": player_input,
		"player_position": live_scene.get("player_position", {}),
		"screenshot_b64": str(live_scene.get("screenshot_b64", "")),
		"scene_context": live_scene.get("scene_context", {})
	}, "player_talk")
	modal_input.text = ""


func _on_guide_updated(steps: Array, current_index: int) -> void:
	var lines: Array[String] = []
	for index in range(steps.size()):
		var prefix := "[color=#2d6a4f]>>[/color]" if index == current_index else "[color=#7a6a50]-[/color]"
		lines.append("%s %s" % [prefix, steps[index]])
	guide_label.text = "\n".join(lines)
