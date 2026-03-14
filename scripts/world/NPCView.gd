extends Node2D
class_name NPCView

const BODY_OUTLINE := Color("221710")
const SPEECH_BUBBLE_TEXTURE_PATH := "res://assets/vendor/opengameart/pixel_speech_bubbles/Sprite Sheet.png"
const PORTRAIT_BASE_PATH := "res://assets/generated/portrait_people"
const MAX_TARGET_STEP_IDLE := 84.0
const MAX_TARGET_STEP_TRAVEL := 132.0
const SPEECH_BUBBLE_FRAME := Vector2i(32, 32)
const SPEECH_BUBBLE_STEP := 34
const ROLE_PROP_ICON_PATHS := {
	"paper": "res://assets/vendor/opengameart/496_RPG_icons/I_Scroll.png",
	"tool": "res://assets/vendor/opengameart/496_RPG_icons/S_Axe01.png",
	"coin": "res://assets/vendor/opengameart/496_RPG_icons/I_GoldCoin.png",
	"ledger": "res://assets/vendor/opengameart/496_RPG_icons/I_Book.png"
}
const ANIMAL_SPRITES := {
	"hero": {"idle_path": "res://assets/generated/character_sheets/hero_idle_sheet.png", "move_path": "res://assets/generated/character_sheets/hero_move_sheet.png", "frame": Vector2i(128, 128), "idle_frames": 4, "move_frames": 8, "scale": 0.66, "ground_offset": 26.0, "family": "square"},
	"base": {"idle_path": "res://assets/generated/character_sheets/base_idle_sheet.png", "move_path": "res://assets/generated/character_sheets/base_move_sheet.png", "frame": Vector2i(128, 128), "idle_frames": 4, "move_frames": 8, "scale": 0.64, "ground_offset": 26.0, "family": "square"},
	"monster": {"idle_path": "res://assets/generated/character_sheets/monster_idle_sheet.png", "move_path": "res://assets/generated/character_sheets/monster_move_sheet.png", "frame": Vector2i(128, 128), "idle_frames": 4, "move_frames": 8, "scale": 0.65, "ground_offset": 26.0, "family": "square"},
	"skeleton": {"idle_path": "res://assets/generated/character_sheets/skeleton_idle_sheet.png", "move_path": "res://assets/generated/character_sheets/skeleton_move_sheet.png", "frame": Vector2i(128, 128), "idle_frames": 4, "move_frames": 8, "scale": 0.64, "ground_offset": 26.0, "family": "square"}
}

var npc_data: Dictionary = {}
var speech_lines: Array = []
var line_index := 0
var line_timer := 0.0
var cadence_seconds := 4.0
var current_line := ""
var show_hearing_debug := false
var wobble_time := 0.0
var blink_time := 0.0
var home_position := Vector2.ZERO
var target_home_position := Vector2.ZERO
var movement_seed := 0.0
var facing_sign := 1.0
var rendered_facing := 1.0
var walk_blend := 0.0
var head_turn := 0.0
var observer_target := Vector2.ZERO
var observer_attention := 0.0
var bubble_alpha := 0.0
var bubble_pop := 0.0
var visual_profile: Dictionary = {}
var speech_phase := 0.0
var speech_blend := 0.0
var stop_settle := 0.0
var stance_lean := 0.0
var speech_impulse := 0.0
var focus_impulse := 0.0
var partner_target := Vector2.ZERO
var social_role := "idle"
var facing_direction := "down"
var sprite_texture_cache: Dictionary = {}
var posture_phase := 0.0
var shoulder_offset := 0.0
var head_bob_bias := 0.0
var bubble_texture: Texture2D
var crowd_phase := 0.0
var listen_impulse := 0.0
var gesture_phase := 0.0
var emote_texture_cache: Dictionary = {}
var social_timer := 0.0
var social_intensity := 0.0
var social_exchange_phase := 0.0
var emotion_role := ""
var emotion_timer := 0.0
var emotion_intensity := 0.0
var emotion_phase := 0.0
var linger_anchor := Vector2.ZERO
var linger_offset := Vector2.ZERO
var linger_timer := 0.0
var linger_intensity := 0.0
var presence_focus := 0.0
var redraw_accumulator := 0.0

var bubble_panel := PanelContainer.new()
var bubble_margin := MarginContainer.new()
var bubble_label := Label.new()
var name_label := Label.new()
var role_label := Label.new()


func _ready() -> void:
	name_label.size = Vector2(124, 18)
	name_label.position = Vector2(-62, 34)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color("f7e5c0"))
	name_label.visible = false
	add_child(name_label)

	role_label.size = Vector2(150, 16)
	role_label.position = Vector2(-75, 48)
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_label.add_theme_font_size_override("font_size", 10)
	role_label.add_theme_color_override("font_color", Color("d7c6a4"))
	role_label.visible = false
	add_child(role_label)

	bubble_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble_panel.size = Vector2(176, 58)
	bubble_panel.position = Vector2(-88, -96)
	add_child(bubble_panel)

	bubble_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	bubble_margin.add_theme_constant_override("margin_left", 9)
	bubble_margin.add_theme_constant_override("margin_top", 6)
	bubble_margin.add_theme_constant_override("margin_right", 9)
	bubble_margin.add_theme_constant_override("margin_bottom", 6)
	bubble_panel.add_child(bubble_margin)

	bubble_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bubble_label.add_theme_color_override("font_color", Color("2c2016"))
	bubble_label.add_theme_font_size_override("font_size", 13)
	bubble_margin.add_child(bubble_label)

	_apply_bubble_theme()
	bubble_panel.visible = false


func apply_data(data: Dictionary, debug_enabled: bool) -> void:
	var previous_target := target_home_position
	npc_data = data
	show_hearing_debug = debug_enabled
	var incoming_target := Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
	var activity := str(data.get("activity", ""))
	var max_step := MAX_TARGET_STEP_TRAVEL if activity in ["commuting", "returning", "traveling", "patrolling"] else MAX_TARGET_STEP_IDLE
	if previous_target != Vector2.ZERO and home_position != Vector2.ZERO:
		var desired_delta := incoming_target - previous_target
		if desired_delta.length() > max_step:
			target_home_position = previous_target.move_toward(incoming_target, max_step)
		else:
			target_home_position = incoming_target
	else:
		target_home_position = incoming_target
	if previous_target == Vector2.ZERO and home_position == Vector2.ZERO:
		home_position = target_home_position
		position = target_home_position
	movement_seed = float(data.get("x", 0.0)) * 0.007 + float(data.get("y", 0.0)) * 0.004 + float(str(data.get("id", "")).length()) * 0.11
	visual_profile = _build_visual_profile(data)
	posture_phase = float(visual_profile.get("posture_phase", movement_seed))
	shoulder_offset = float(visual_profile.get("shoulder_offset", 0.0))
	head_bob_bias = float(visual_profile.get("head_bob_bias", 0.0))
	crowd_phase = float(visual_profile.get("crowd_phase", movement_seed))
	gesture_phase = float(visual_profile.get("gesture_phase", movement_seed))
	var move_delta := target_home_position - previous_target
	if move_delta.length() > 2.0 and abs(move_delta.x) > 0.6:
		facing_sign = -1.0 if move_delta.x < 0.0 else 1.0
	name_label.text = str(data.get("name", ""))
	var title := str(data.get("title", ""))
	if title.is_empty():
		title = str(data.get("role", ""))
	role_label.text = "%s | %s | %s" % [
		str(data.get("species", "")),
		title,
		_activity_text(str(data.get("activity", "")))
	]
	_apply_name_theme()
	_apply_bubble_theme()
	var next_lines: Array = data.get("speech_lines", [])
	if next_lines != speech_lines:
		speech_lines = next_lines.duplicate()
		line_index = 0
		current_line = ""
		line_timer = cadence_seconds
	cadence_seconds = max(float(data.get("cadence_seconds", 4.0)), 1.5)
	if current_line.is_empty() and speech_lines.size() > 0:
		current_line = str(speech_lines[0])
		_refresh_bubble()
	queue_redraw()


func set_observer_target(target: Vector2, attention: float) -> void:
	observer_target = target
	observer_attention = max(observer_attention, clampf(attention, 0.0, 1.0))


func set_presence_focus(focus: float) -> void:
	presence_focus = clampf(focus, 0.0, 1.0)


func trigger_social_beat(target: Vector2, speaking: bool, role_override: String = "", duration: float = 0.0, intensity: float = 1.0) -> void:
	partner_target = target
	observer_target = target
	var role := role_override if not role_override.is_empty() else ("speaker" if speaking else "listener")
	var strength := clampf(intensity, 0.35, 1.5)
	match role:
		"speaker":
			observer_attention = max(observer_attention, 0.9 * strength)
			speech_impulse = max(speech_impulse, 1.0 * strength)
			focus_impulse = max(focus_impulse, 1.0 * strength)
			listen_impulse = max(listen_impulse, 0.35 * strength)
			bubble_pop = max(bubble_pop, 0.48 * strength)
		"listener":
			observer_attention = max(observer_attention, 0.72 * strength)
			speech_impulse = max(speech_impulse, 0.28 * strength)
			focus_impulse = max(focus_impulse, 0.95 * strength)
			listen_impulse = max(listen_impulse, 0.9 * strength)
			bubble_pop = max(bubble_pop, 0.24 * strength)
		"interject":
			observer_attention = max(observer_attention, 0.85 * strength)
			speech_impulse = max(speech_impulse, 0.88 * strength)
			focus_impulse = max(focus_impulse, 1.15 * strength)
			listen_impulse = max(listen_impulse, 0.52 * strength)
			bubble_pop = max(bubble_pop, 0.42 * strength)
		"yield":
			observer_attention = max(observer_attention, 0.64 * strength)
			speech_impulse = max(speech_impulse, 0.18 * strength)
			focus_impulse = max(focus_impulse, 0.72 * strength)
			listen_impulse = max(listen_impulse, 0.76 * strength)
			bubble_pop = max(bubble_pop, 0.18 * strength)
		"pause":
			observer_attention = max(observer_attention, 0.56 * strength)
			speech_impulse = max(speech_impulse, 0.12 * strength)
			focus_impulse = max(focus_impulse, 0.58 * strength)
			listen_impulse = max(listen_impulse, 0.32 * strength)
			bubble_pop = max(bubble_pop, 0.12 * strength)
		"bystand":
			observer_attention = max(observer_attention, 0.62 * strength)
			speech_impulse = max(speech_impulse, 0.14 * strength)
			focus_impulse = max(focus_impulse, 0.74 * strength)
			listen_impulse = max(listen_impulse, 0.66 * strength)
			bubble_pop = max(bubble_pop, 0.16 * strength)
		"glance":
			observer_attention = max(observer_attention, 0.52 * strength)
			speech_impulse = max(speech_impulse, 0.06 * strength)
			focus_impulse = max(focus_impulse, 0.66 * strength)
			listen_impulse = max(listen_impulse, 0.24 * strength)
			bubble_pop = max(bubble_pop, 0.06 * strength)
		"slowpass":
			observer_attention = max(observer_attention, 0.58 * strength)
			speech_impulse = max(speech_impulse, 0.08 * strength)
			focus_impulse = max(focus_impulse, 0.78 * strength)
			listen_impulse = max(listen_impulse, 0.18 * strength)
			bubble_pop = max(bubble_pop, 0.08 * strength)
		"disperse":
			observer_attention = max(observer_attention, 0.48 * strength)
			speech_impulse = max(speech_impulse, 0.08 * strength)
			focus_impulse = max(focus_impulse, 0.82 * strength)
			listen_impulse = max(listen_impulse, 0.14 * strength)
			bubble_pop = max(bubble_pop, 0.08 * strength)
		"dismiss":
			observer_attention = max(observer_attention, 0.42 * strength)
			speech_impulse = max(speech_impulse, 0.1 * strength)
			focus_impulse = max(focus_impulse, 0.92 * strength)
			listen_impulse = max(listen_impulse, 0.08 * strength)
			bubble_pop = max(bubble_pop, 0.1 * strength)
		_:
			observer_attention = max(observer_attention, 0.7 * strength)
			speech_impulse = max(speech_impulse, 0.4 * strength)
			focus_impulse = max(focus_impulse, 0.8 * strength)
			listen_impulse = max(listen_impulse, 0.4 * strength)
	social_role = role
	social_timer = max(social_timer, duration if duration > 0.0 else _social_role_duration(role))
	social_intensity = max(social_intensity, strength)
	social_exchange_phase = randf_range(0.0, TAU)


func trigger_emotion_wave(emotion: String, source: Vector2, duration: float = 0.0, intensity: float = 1.0) -> void:
	if emotion.is_empty():
		return
	var strength := clampf(intensity, 0.25, 1.45)
	emotion_role = emotion
	emotion_timer = max(emotion_timer, duration if duration > 0.0 else _emotion_duration(emotion))
	emotion_intensity = max(emotion_intensity, strength)
	emotion_phase = randf_range(0.0, TAU)
	if source != Vector2.ZERO:
		observer_target = source
		partner_target = source
	match emotion:
		"puzzled":
			observer_attention = max(observer_attention, 0.72 * strength)
			focus_impulse = max(focus_impulse, 0.82 * strength)
			listen_impulse = max(listen_impulse, 0.72 * strength)
			bubble_pop = max(bubble_pop, 0.12 * strength)
		"startled":
			observer_attention = max(observer_attention, 1.0 * strength)
			focus_impulse = max(focus_impulse, 1.08 * strength)
			listen_impulse = max(listen_impulse, 0.45 * strength)
			speech_impulse = max(speech_impulse, 0.18 * strength)
			bubble_pop = max(bubble_pop, 0.32 * strength)
		"scoff":
			observer_attention = max(observer_attention, 0.62 * strength)
			focus_impulse = max(focus_impulse, 0.66 * strength)
			speech_impulse = max(speech_impulse, 0.2 * strength)
			bubble_pop = max(bubble_pop, 0.14 * strength)
		"hurry":
			observer_attention = max(observer_attention, 0.78 * strength)
			focus_impulse = max(focus_impulse, 0.92 * strength)
			listen_impulse = max(listen_impulse, 0.18 * strength)
			bubble_pop = max(bubble_pop, 0.08 * strength)
		_:
			observer_attention = max(observer_attention, 0.58 * strength)
			focus_impulse = max(focus_impulse, 0.64 * strength)


func set_social_linger(anchor: Vector2, offset: Vector2, duration: float = 0.0, intensity: float = 1.0) -> void:
	linger_anchor = anchor
	linger_offset = offset
	linger_timer = max(linger_timer, duration if duration > 0.0 else 1.1)
	linger_intensity = max(linger_intensity, clampf(intensity, 0.2, 1.3))
	observer_target = anchor
	partner_target = anchor
	observer_attention = max(observer_attention, 0.34 + linger_intensity * 0.22)


func get_npc_id() -> String:
	return str(npc_data.get("id", ""))


func get_current_line() -> String:
	return current_line


func get_social_radius() -> float:
	return float(npc_data.get("social_radius", 180.0))


func get_district() -> String:
	return str(npc_data.get("district", ""))


func get_role() -> String:
	return str(npc_data.get("role", ""))


func get_activity() -> String:
	return str(npc_data.get("activity", ""))


func get_prop() -> String:
	return str(visual_profile.get("prop", "gesture"))


func _process(delta: float) -> void:
	wobble_time += delta
	blink_time += delta * (0.82 + movement_seed * 0.02 + float(visual_profile.get("blink_bias", 0.0)))
	var previous_home := home_position
	var social_travel_scale := 1.0
	match social_role:
		"slowpass":
			social_travel_scale = 0.52 + (1.0 - clampf(social_intensity, 0.0, 1.0)) * 0.18
		"bystand":
			social_travel_scale = 0.72
		"glance":
			social_travel_scale = 0.82
		"pause":
			social_travel_scale = 0.4
	match emotion_role:
		"hurry":
			social_travel_scale *= 1.26 + clampf(emotion_intensity, 0.0, 1.0) * 0.16
		"startled":
			social_travel_scale *= 0.82
	if linger_timer > 0.0:
		social_travel_scale *= 0.9 + linger_intensity * 0.12
	var desired_home := target_home_position
	if linger_timer > 0.0:
		desired_home = linger_anchor + linger_offset
	home_position = home_position.lerp(
		desired_home,
		min(delta * (float(visual_profile.get("travel_rate", 2.4)) + float(visual_profile.get("pace", 0.0))) * social_travel_scale * 0.62, 1.0)
	)
	var velocity := home_position - previous_home
	var wants_walk := velocity.length() > 0.3 or desired_home.distance_to(home_position) > 3.2
	walk_blend = move_toward(walk_blend, 1.0 if wants_walk else 0.0, delta * float(visual_profile.get("walk_blend_rate", 4.0)))
	stop_settle = lerpf(stop_settle, velocity.y * 0.3, min(delta * float(visual_profile.get("settle_rate", 4.2)), 1.0))
	if wants_walk and velocity.length() > 0.08:
		facing_direction = _direction_name_for_vector(velocity)
	if wants_walk and abs(velocity.x) > 0.08:
		facing_sign = -1.0 if velocity.x < 0.0 else 1.0
	elif observer_attention > 0.26 and abs(observer_target.x - home_position.x) > 8.0:
		facing_sign = -1.0 if observer_target.x < home_position.x else 1.0
		facing_direction = "left" if observer_target.x < home_position.x else "right"
	elif observer_attention > 0.26 and abs(observer_target.y - home_position.y) > abs(observer_target.x - home_position.x):
		facing_direction = "up" if observer_target.y < home_position.y else "down"
	rendered_facing = lerpf(rendered_facing, facing_sign, min(delta * float(visual_profile.get("turn_rate", 7.0)), 1.0))

	var idle_drift := Vector2(
		sin(wobble_time * (1.2 + float(visual_profile.get("idle_rate", 0.0))) + posture_phase) * (1.8 + float(visual_profile.get("restless", 0.0)) * 0.6),
		cos(wobble_time * (1.05 + float(visual_profile.get("idle_rate", 0.0)) * 0.6) + movement_seed * 1.4 + posture_phase) * (0.9 + head_bob_bias * 0.25)
	) * (1.0 - walk_blend)
	position = home_position + idle_drift

	var desired_head_turn := sin(wobble_time * 0.72 + posture_phase) * (0.14 + float(visual_profile.get("look_bias", 0.0)) * 0.03) * (1.0 - walk_blend)
	if observer_attention > 0.01:
		desired_head_turn += clampf((observer_target.x - position.x) / 78.0, -1.0, 1.0) * observer_attention
	head_turn = lerpf(head_turn, desired_head_turn, min(delta * 4.8, 1.0))
	observer_attention = move_toward(observer_attention, 0.0, delta * 1.4)
	speech_impulse = move_toward(speech_impulse, 0.0, delta * 2.3)
	focus_impulse = move_toward(focus_impulse, 0.0, delta * 2.8)
	listen_impulse = move_toward(listen_impulse, 0.0, delta * 3.2)
	social_intensity = move_toward(social_intensity, 0.0, delta * 1.9)
	social_timer = max(social_timer - delta, 0.0)
	emotion_intensity = move_toward(emotion_intensity, 0.0, delta * 1.8)
	emotion_timer = max(emotion_timer - delta, 0.0)
	linger_intensity = move_toward(linger_intensity, 0.0, delta * 1.7)
	linger_timer = max(linger_timer - delta, 0.0)
	if social_timer <= 0.0 and speech_impulse <= 0.02 and focus_impulse <= 0.02 and bubble_alpha <= 0.05:
		social_role = "idle"
	if emotion_timer <= 0.0 and emotion_intensity <= 0.04:
		emotion_role = ""
	if linger_timer <= 0.0 and linger_intensity <= 0.04:
		linger_offset = Vector2.ZERO
	speech_blend = move_toward(speech_blend, 1.0 if bubble_alpha > 0.1 else 0.0, delta * 4.0)
	speech_phase += delta * (6.2 + float(visual_profile.get("speech_rate", 0.0)))
	stance_lean = lerpf(stance_lean, _stance_bias(), min(delta * 2.8, 1.0))

	var should_show_bubble := not current_line.is_empty() and (
		show_hearing_debug
		or presence_focus > 0.84
		or observer_attention > 0.5
		or social_timer > 0.22
		or emotion_timer > 0.22
	)
	bubble_alpha = move_toward(bubble_alpha, 1.0 if should_show_bubble else 0.0, delta * 4.2)
	bubble_pop = move_toward(bubble_pop, 0.0, delta * 4.8)
	_update_label_layout()
	_update_bubble_layout()

	line_timer -= delta
	if line_timer <= 0.0:
		line_timer = cadence_seconds
		if speech_lines.size() > 0:
			line_index = (line_index + 1) % speech_lines.size()
			current_line = str(speech_lines[line_index])
			_refresh_bubble()
	var active_visual := (
		walk_blend > 0.08
		or bubble_alpha > 0.03
		or observer_attention > 0.05
		or speech_blend > 0.04
		or social_timer > 0.0
		or emotion_timer > 0.0
		or linger_timer > 0.0
		or presence_focus > 0.48
	)
	redraw_accumulator += delta
	var redraw_interval := 0.04 if active_visual else 0.16
	if redraw_accumulator >= redraw_interval:
		redraw_accumulator = 0.0
		queue_redraw()


func _update_label_layout() -> void:
	var settle: float = 1.0 - walk_blend
	var lift: float = -abs(sin(wobble_time * (1.25 + float(visual_profile.get("idle_rate", 0.0)) * 0.3) + posture_phase)) * (1.2 + head_bob_bias * 0.2) * settle
	name_label.position = Vector2(-62, 35 + lift + shoulder_offset * 0.15)
	role_label.position = Vector2(-75, 49 + lift + shoulder_offset * 0.15)
	var show_name := presence_focus > 0.72 or bubble_alpha > 0.16 or show_hearing_debug
	var show_role := presence_focus > 0.9 or bubble_alpha > 0.24 or show_hearing_debug
	name_label.visible = show_name
	role_label.visible = show_role
	name_label.modulate = Color(1, 1, 1, clampf(0.08 + presence_focus * 0.8 + bubble_alpha * 0.32, 0.0, 1.0))
	role_label.modulate = Color(1, 1, 1, clampf(presence_focus * 0.58 + bubble_alpha * 0.24, 0.0, 1.0))


func _update_bubble_layout() -> void:
	var float_y: float = sin(wobble_time * 2.2 + posture_phase) * (1.5 + head_bob_bias * 0.2) - speech_blend * abs(sin(speech_phase)) * 1.6 - speech_impulse * 1.2
	var bubble_height: float = float(visual_profile.get("bubble_height", 92.0))
	var horizontal_bias := sin(movement_seed * 3.7 + crowd_phase) * 18.0
	bubble_panel.position = Vector2(-bubble_panel.size.x * 0.5 + horizontal_bias, -bubble_height + float_y - bubble_panel.size.y)
	bubble_panel.modulate = Color(1, 1, 1, bubble_alpha)
	bubble_panel.scale = Vector2.ONE * (1.0 + bubble_pop * 0.08 + speech_blend * 0.015 + speech_impulse * 0.035)
	bubble_panel.visible = bubble_alpha > 0.02


func _apply_name_theme() -> void:
	var relation := int(npc_data.get("player_relation", 0))
	var relation_color := Color("f7e5c0")
	if relation >= 3:
		relation_color = Color("fde8a5")
	elif relation <= -1:
		relation_color = Color("f0c6af")
	name_label.add_theme_color_override("font_color", relation_color)


func _refresh_bubble() -> void:
	bubble_label.text = current_line
	var char_count: int = current_line.length()
	var line_count: int = max(1, int(ceil(float(char_count) / 11.5)))
	bubble_panel.size = Vector2(clampf(102.0 + float(char_count) * 8.0, 114.0, 228.0), 24.0 + float(line_count) * 18.0)
	bubble_pop = 1.0
	_update_bubble_layout()


func _apply_bubble_theme() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0)
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	bubble_panel.add_theme_stylebox_override("panel", style)


func _draw() -> void:
	var stride_scale: float = float(visual_profile.get("stride_scale", 1.0))
	var stride: float = sin(wobble_time * ((7.0 if walk_blend > 0.18 else 2.4) + float(visual_profile.get("stride_rate", 0.0))) + crowd_phase) * ((4.5 + float(visual_profile.get("stride_height", 0.0))) * walk_blend * stride_scale)
	var speech_bob: float = abs(sin(speech_phase)) * speech_blend * 0.9
	var listen_nod: float = abs(sin(wobble_time * 5.2 + crowd_phase)) * listen_impulse
	var bob: float = -abs(stride) * 0.42 - walk_blend * 1.1 + sin(wobble_time * (1.34 + float(visual_profile.get("idle_rate", 0.0)) * 0.4) + posture_phase) * 0.35 * (1.0 - walk_blend) - stop_settle * 0.6 - speech_bob * 0.2 - listen_nod * 0.22
	var labor_breath: float = float(visual_profile.get("labor_breath", 0.0)) * (1.0 - walk_blend) * (0.55 + min(abs(stop_settle) * 1.8, 0.65))
	var breathe: float = sin(wobble_time * (1.76 + float(visual_profile.get("breath_rate", 0.0))) + posture_phase * 0.7) * ((1.35 + head_bob_bias * 0.1) - walk_blend * 0.5) + sin(wobble_time * 2.5 + crowd_phase) * labor_breath
	var blink_closed: bool = fmod(blink_time, 4.65) > 4.15
	var tilt: float = head_turn * 0.08 + stride * 0.016 + stance_lean * 0.06 + focus_impulse * 0.03 * signf(rendered_facing)
	var look: Vector2 = Vector2(clampf(head_turn, -1.0, 1.0), 0.0)
	var accent: Color = _accent_color()
	var cloth: Color = _cloth_color(_body_color())
	var skin: Color = _skin_color()
	var speaker_weight: float = 1.0 if social_role == "speaker" else 0.0
	var listener_weight: float = 1.0 if social_role == "listener" else 0.0
	var interject_weight: float = 1.0 if social_role == "interject" else 0.0
	var yield_weight: float = 1.0 if social_role == "yield" else 0.0
	var pause_weight: float = 1.0 if social_role == "pause" else 0.0
	var bystand_weight: float = 1.0 if social_role == "bystand" else 0.0
	var glance_weight: float = 1.0 if social_role == "glance" else 0.0
	var slowpass_weight: float = 1.0 if social_role == "slowpass" else 0.0
	var disperse_weight: float = 1.0 if social_role == "disperse" else 0.0
	var dismiss_weight: float = 1.0 if social_role == "dismiss" else 0.0
	var puzzled_weight: float = emotion_intensity if emotion_role == "puzzled" else 0.0
	var startled_weight: float = emotion_intensity if emotion_role == "startled" else 0.0
	var scoff_weight: float = emotion_intensity if emotion_role == "scoff" else 0.0
	var hurry_weight: float = emotion_intensity if emotion_role == "hurry" else 0.0
	var idle_prop := str(visual_profile.get("prop", "gesture"))
	var exchange_wave: float = sin(wobble_time * 4.6 + social_exchange_phase) * social_intensity
	var crowd_lean: float = sin(wobble_time * 0.92 + gesture_phase) * 0.7 * (1.0 - walk_blend) + interject_weight * 0.9 * rendered_facing + bystand_weight * 0.32 * rendered_facing + glance_weight * 0.24 * rendered_facing + slowpass_weight * 0.18 * rendered_facing + puzzled_weight * 0.22 * rendered_facing - yield_weight * 0.6 * rendered_facing - disperse_weight * 1.1 * rendered_facing - dismiss_weight * 1.25 * rendered_facing - scoff_weight * 0.42 * rendered_facing - hurry_weight * 0.28 * rendered_facing
	var idle_role_weight: float = _role_idle_weight()
	var idle_pose := _role_idle_pose(idle_prop, idle_role_weight)
	var torso_center: Vector2 = Vector2(shoulder_offset * 0.2 + crowd_lean + speaker_weight * 0.75 * rendered_facing - listener_weight * 0.35 * rendered_facing + interject_weight * exchange_wave * 0.6, -6 + bob + yield_weight * 0.7 + pause_weight * 0.45 + bystand_weight * 0.28 + glance_weight * 0.12 + slowpass_weight * 0.16 + dismiss_weight * 0.18 + puzzled_weight * 0.22 - startled_weight * 1.05 - hurry_weight * 0.42 + scoff_weight * 0.12) + idle_pose.get("torso", Vector2.ZERO)
	var leg_origin: Vector2 = torso_center + Vector2(0, 10 + breathe)
	var head_center: Vector2 = torso_center + Vector2((focus_impulse * 1.2 + speaker_weight * 1.4 - listener_weight * 0.35 + interject_weight * 1.2 + bystand_weight * 0.6 + glance_weight * 0.95 + slowpass_weight * 0.7 + puzzled_weight * 0.55 + startled_weight * 0.4 - disperse_weight * 1.1 - dismiss_weight * 1.35 - scoff_weight * 0.7 - hurry_weight * 0.55) * rendered_facing, -20 + breathe * 0.5 - speech_impulse * 0.5 - listen_nod * 1.3 + pause_weight * 1.1 + yield_weight * 0.7 + bystand_weight * 0.55 + glance_weight * 0.28 + slowpass_weight * 0.18 + dismiss_weight * 0.22 - puzzled_weight * 0.48 - startled_weight * 1.9 + scoff_weight * 0.82 + hurry_weight * 0.35) + idle_pose.get("head", Vector2.ZERO)
	var talk_open: float = speech_blend * (0.7 + 0.3 * sin(speech_phase)) * (0.4 + 0.6 * speaker_weight + 0.45 * interject_weight) + speech_impulse * (0.28 + 0.22 * speaker_weight + 0.18 * interject_weight)
	var gesture_swing: float = sin(speech_phase * 0.72 + gesture_phase + social_exchange_phase) * (0.8 + speaker_weight * 1.6 + listener_weight * 0.45 + interject_weight * 1.05)

	_draw_shadow(Vector2(0, 24), Vector2(17 + walk_blend * 2.4, 7.0), 0.17)
	if bubble_alpha > 0.02:
		_draw_bubble_backplate()
		_draw_speech_tail(head_center)
	_draw_sprite_body(torso_center, stride, bob)
	if not _uses_custom_portrait():
		_draw_species_tail(torso_center, accent, cloth)
		_draw_sprite_accessories(torso_center, head_center, accent, cloth, speaker_weight, listener_weight, interject_weight, yield_weight, pause_weight, bystand_weight, glance_weight, slowpass_weight, disperse_weight, dismiss_weight, puzzled_weight, startled_weight, scoff_weight, hurry_weight, talk_open, gesture_swing, listen_nod, idle_role_weight)
		_draw_role_walk(torso_center, head_center, accent, cloth, walk_blend)
		_draw_role_prop(torso_center + Vector2(6 * rendered_facing, 0), bob, accent)
	_draw_commute_carry_prop(torso_center + Vector2(6 * rendered_facing, 0), bob, accent, cloth)
	_draw_emote_icon(head_center)

	if int(npc_data.get("player_relation", 0)) >= 3:
		draw_circle(Vector2(15, -28 + bob), 4.0, Color("c3b063"))
		draw_circle(Vector2(15, -28 + bob), 2.0, Color("f3deb0"))
	if show_hearing_debug:
		draw_arc(Vector2.ZERO, get_social_radius(), 0.0, TAU, 48, Color(0.92, 0.85, 0.61, 0.35), 1.5)


func _draw_speech_tail(head_center: Vector2) -> void:
	var bubble_rect := _bubble_visual_rect()
	var base_left := bubble_rect.position + Vector2(bubble_rect.size.x * 0.42, bubble_rect.size.y)
	var base_right := bubble_rect.position + Vector2(bubble_rect.size.x * 0.58, bubble_rect.size.y)
	var tip := head_center + Vector2(rendered_facing * 2.0, -9.0)
	var fill := _speech_fill_color().lightened(0.06)
	var border := _accent_color().darkened(0.42)
	var points := PackedVector2Array([base_left, base_right, tip])
	draw_colored_polygon(points, fill)
	_draw_outline(PackedVector2Array([base_left, base_right, tip]), border, 1.2, true)


func _draw_bubble_backplate() -> void:
	var bubble_rect := _bubble_visual_rect()
	var shadow_rect := Rect2(bubble_rect.position + Vector2(3, 4), bubble_rect.size)
	draw_rect(shadow_rect, Color(0, 0, 0, 0.12 * bubble_alpha), true)
	draw_rect(bubble_rect, _speech_fill_color().lightened(0.04), true)
	draw_rect(bubble_rect, _accent_color().darkened(0.42), false, 2.0)


func _bubble_visual_rect() -> Rect2:
	var scale_value := bubble_panel.scale.x
	var size := bubble_panel.size * scale_value
	var position_offset := (bubble_panel.size - size) * 0.5
	return Rect2(bubble_panel.position + position_offset, size)


func _bubble_source_rect() -> Rect2:
	var bubble_frame := Vector2i(1, 0)
	if social_role == "listener":
		bubble_frame = Vector2i(0, 0)
	var mood := str(npc_data.get("mood", ""))
	if mood == "tired":
		bubble_frame = Vector2i(0, 2)
	elif mood == "excited":
		bubble_frame = Vector2i(1, 1)
	elif mood == "anxious":
		bubble_frame = Vector2i(0, 1)
	return Rect2(
		Vector2(bubble_frame.x * SPEECH_BUBBLE_STEP, bubble_frame.y * SPEECH_BUBBLE_STEP),
		Vector2(SPEECH_BUBBLE_FRAME)
	)


func _load_bubble_texture() -> Texture2D:
	if bubble_texture != null:
		return bubble_texture
	var image := Image.load_from_file(ProjectSettings.globalize_path(SPEECH_BUBBLE_TEXTURE_PATH))
	if image == null or image.is_empty():
		return null
	bubble_texture = ImageTexture.create_from_image(image)
	return bubble_texture


func _draw_sprite_body(center: Vector2, stride: float, bob: float) -> void:
	var meta: Dictionary = _sprite_meta()
	var moving := walk_blend > 0.16 or str(npc_data.get("activity", "")) in ["commuting", "returning"]
	var texture_path := str(meta.get("move_path" if moving else "idle_path", ""))
	var texture: Texture2D = _load_sprite_texture(texture_path)
	if texture == null:
		return
	var frame_size: Vector2i = meta.get("frame", Vector2i(64, 64))
	var frame_count := int(meta.get("move_frames" if moving else "idle_frames", 4))
	var frame := _sprite_frame_index(frame_count, moving)
	var row := _sprite_row_for_direction(facing_direction)
	var src_rect := Rect2(frame * frame_size.x, row * frame_size.y, frame_size.x, frame_size.y)
	var scale_value: float = float(meta.get("scale", 2.1)) + float(visual_profile.get("sprite_scale_bias", 0.0))
	var draw_size := Vector2(frame_size.x, frame_size.y) * scale_value
	var ground_offset: float = float(meta.get("ground_offset", 16.0))
	var draw_pos := center + Vector2(-draw_size.x * 0.5, -draw_size.y + ground_offset - abs(stride) * 0.08)
	var modulate := _sprite_modulate()
	draw_texture_rect_region(texture, Rect2(draw_pos, draw_size), src_rect, modulate)
	draw_rect(
		Rect2(draw_pos + Vector2(draw_size.x * 0.18, draw_size.y - 8), Vector2(draw_size.x * 0.64, 4)),
		Color(1, 1, 1, 0.06),
		true
	)


func _draw_sprite_accessories(center: Vector2, head_center: Vector2, accent: Color, cloth: Color, speaker_weight: float, listener_weight: float, interject_weight: float, yield_weight: float, pause_weight: float, bystand_weight: float, glance_weight: float, slowpass_weight: float, disperse_weight: float, dismiss_weight: float, puzzled_weight: float, startled_weight: float, scoff_weight: float, hurry_weight: float, talk_open: float, gesture_swing: float, listen_nod: float, idle_role_weight: float) -> void:
	if bool(visual_profile.get("neck_scarf", false)):
		_draw_collar(head_center.y + 8.0, accent)
	if bool(visual_profile.get("hat", "none") != "none"):
		_draw_hat(head_center, accent)
	if bool(visual_profile.get("satchel", false)):
		_draw_satchel(center + Vector2(12 * rendered_facing, 4), accent)
	if speaker_weight > 0.0:
		var hand := center + Vector2((12.0 + gesture_swing * 2.0) * rendered_facing, -4.0 - talk_open * 1.5)
		draw_line(center + Vector2(6 * rendered_facing, 1), hand, accent.lightened(0.08), 2.0)
		draw_circle(hand, 1.7, accent.lightened(0.18))
		draw_circle(head_center + Vector2(7 * rendered_facing, 2 + talk_open), 1.4, accent.lightened(0.18))
	if listener_weight > 0.0:
		draw_line(
			center + Vector2(5 * rendered_facing, 1),
			center + Vector2(9 * rendered_facing, 4 + listen_nod * 1.4),
			cloth.lightened(0.08),
			1.7
		)
		draw_circle(head_center + Vector2(-5 * rendered_facing, -1 - listen_nod * 0.8), 1.0, Color(1, 1, 1, 0.24))
	if interject_weight > 0.0:
		var interject_hand := center + Vector2((13.0 + gesture_swing * 1.2) * rendered_facing, -7.0 - talk_open * 1.8)
		draw_line(center + Vector2(6 * rendered_facing, 0), interject_hand, accent.lightened(0.12), 2.1)
		draw_circle(interject_hand, 1.9, accent.lightened(0.22))
		draw_line(head_center + Vector2(3 * rendered_facing, 4), head_center + Vector2(8 * rendered_facing, 3), BODY_OUTLINE, 1.2)
	if yield_weight > 0.0:
		draw_line(center + Vector2(3 * rendered_facing, 2), center + Vector2(9 * rendered_facing, 8), cloth.darkened(0.08), 1.8)
		draw_circle(head_center + Vector2(-4 * rendered_facing, 3), 0.9, Color(1, 1, 1, 0.22))
	if pause_weight > 0.0:
		draw_line(head_center + Vector2(-3, 3), head_center + Vector2(3, 3), BODY_OUTLINE, 1.0)
	if bystand_weight > 0.0:
		draw_line(center + Vector2(4 * rendered_facing, 1), center + Vector2(8 * rendered_facing, 5), cloth.lightened(0.02), 1.6)
		draw_circle(head_center + Vector2(-2 * rendered_facing, 1), 0.8, Color(1, 1, 1, 0.18))
	if glance_weight > 0.0:
		draw_line(head_center + Vector2(-3, 2), head_center + Vector2(3, 1), BODY_OUTLINE, 1.0)
		draw_circle(head_center + Vector2(4 * rendered_facing, -1), 0.8, Color(1, 1, 1, 0.15))
	if slowpass_weight > 0.0:
		draw_line(center + Vector2(4 * rendered_facing, 1), center + Vector2(10 * rendered_facing, 5), cloth.lightened(0.04), 1.7)
	if disperse_weight > 0.0:
		draw_line(center + Vector2(-4 * rendered_facing, 1), center + Vector2(-10 * rendered_facing, 7), cloth.darkened(0.18), 1.8)
	if dismiss_weight > 0.0:
		draw_line(head_center + Vector2(-3, 2), head_center + Vector2(3, 4), BODY_OUTLINE, 1.0)
		draw_line(center + Vector2(-3 * rendered_facing, 2), center + Vector2(-9 * rendered_facing, 7), cloth.darkened(0.18), 1.7)
	if puzzled_weight > 0.0:
		draw_line(head_center + Vector2(-4 * rendered_facing, -3), head_center + Vector2(2 * rendered_facing, -1), BODY_OUTLINE, 1.0)
		draw_circle(head_center + Vector2(5 * rendered_facing, -4), 0.85 + puzzled_weight * 0.45, Color(1, 1, 1, 0.16 + puzzled_weight * 0.12))
	if startled_weight > 0.0:
		var startle_hand := center + Vector2((12.0 + startled_weight * 2.0) * rendered_facing, -9.0 - startled_weight * 2.4)
		draw_line(center + Vector2(6 * rendered_facing, -1), startle_hand, accent.lightened(0.12), 1.9)
		draw_circle(startle_hand, 1.6, accent.lightened(0.2))
		draw_line(head_center + Vector2(4 * rendered_facing, -8), head_center + Vector2(6 * rendered_facing, -13), BODY_OUTLINE, 1.0)
	if scoff_weight > 0.0:
		draw_arc(head_center + Vector2(2.0 * rendered_facing, 4.0), 2.7, PI * 0.05, PI * 0.82, 8, BODY_OUTLINE, 1.0)
		draw_line(center + Vector2(4 * rendered_facing, 2), center + Vector2(9 * rendered_facing, 7), cloth.darkened(0.08), 1.7)
	if hurry_weight > 0.0:
		draw_line(center + Vector2(-6 * rendered_facing, -1), center + Vector2(-13 * rendered_facing, 2), cloth.darkened(0.16), 1.2)
		draw_line(center + Vector2(-5 * rendered_facing, 3), center + Vector2(-11 * rendered_facing, 7), cloth.darkened(0.16), 1.1)
	if idle_role_weight > 0.0:
		_draw_role_idle(center, head_center, accent, cloth, idle_role_weight)
	draw_line(center + Vector2(-6, 14), center + Vector2(6, 14), cloth.darkened(0.22), 2.0)


func _social_role_duration(role: String) -> float:
	match role:
		"speaker":
			return 1.1
		"listener":
			return 0.95
		"interject":
			return 0.7
		"yield":
			return 0.8
		"pause":
			return 0.65
		"bystand":
			return 1.25
		"glance":
			return 0.72
		"slowpass":
			return 1.0
		"disperse":
			return 0.9
		"dismiss":
			return 0.88
	return 0.75


func _emotion_duration(emotion: String) -> float:
	match emotion:
		"puzzled":
			return 1.08
		"startled":
			return 0.82
		"scoff":
			return 0.9
		"hurry":
			return 1.15
	return 0.84


func _role_idle_weight() -> float:
	if walk_blend > 0.08:
		return 0.0
	if social_role != "idle":
		return 0.0
	var prop := str(visual_profile.get("prop", "gesture"))
	if prop in ["tool", "paper", "cane", "ledger", "coin", "megaphone"]:
		return 1.0
	if bool(visual_profile.get("satchel", false)) and str(visual_profile.get("garment", "")) == "vest":
		return 0.8
	return 0.0


func _role_idle_pose(prop: String, weight: float) -> Dictionary:
	match prop:
		"paper":
			return {"torso": Vector2(0.8 * rendered_facing * weight, 0.2), "head": Vector2(1.8 * rendered_facing * weight, 1.0)}
		"cane":
			return {"torso": Vector2(-0.8 * rendered_facing * weight, -0.3), "head": Vector2(-1.2 * rendered_facing * weight, -0.2)}
		"tool":
			return {"torso": Vector2(0.2, 0.8 * weight), "head": Vector2(0.8 * rendered_facing * weight, 0.5 * weight)}
		"ledger":
			return {"torso": Vector2(0.7 * rendered_facing * weight, 0.5), "head": Vector2(1.4 * rendered_facing * weight, 1.2)}
		"coin":
			return {"torso": Vector2(0.5 * rendered_facing * weight, -0.1), "head": Vector2(1.0 * rendered_facing * weight, -0.2)}
		"megaphone":
			return {"torso": Vector2(0.6 * rendered_facing * weight, -0.1), "head": Vector2(1.2 * rendered_facing * weight, -0.5)}
	return {"torso": Vector2.ZERO, "head": Vector2.ZERO}


func _draw_role_idle(center: Vector2, head_center: Vector2, accent: Color, cloth: Color, weight: float) -> void:
	var prop := str(visual_profile.get("prop", "gesture"))
	var idle_wave := sin(wobble_time * (1.8 + weight * 0.2) + gesture_phase)
	match prop:
		"paper":
			var notebook_center := center + Vector2(11 * rendered_facing, 2 + idle_wave * 0.8)
			_draw_role_prop_icon("paper", notebook_center, 15.0)
			var pen_hand := center + Vector2((7.0 + idle_wave * 1.5) * rendered_facing, -2.0)
			draw_line(center + Vector2(4 * rendered_facing, -1), pen_hand, accent.darkened(0.08), 1.8)
			draw_line(pen_hand, notebook_center + Vector2(-2 * rendered_facing, -2), Color("f5e4b8"), 1.2)
			draw_line(notebook_center + Vector2(-2 * rendered_facing, -1), notebook_center + Vector2(2 * rendered_facing, 1), BODY_OUTLINE, 1.0)
		"cane":
			var chin_hand := head_center + Vector2(3.5 * rendered_facing, 7.0 + idle_wave * 0.6)
			draw_line(center + Vector2(5 * rendered_facing, 1), chin_hand, cloth.lightened(0.08), 2.0)
			draw_circle(chin_hand, 1.8, accent.lightened(0.14))
			draw_arc(head_center + Vector2(4.0 * rendered_facing, 4.5), 2.8, PI * 0.1, PI * 0.9, 10, BODY_OUTLINE, 1.1)
		"tool":
			var brow_hand := head_center + Vector2(5.0 * rendered_facing, -5.0 + idle_wave * 0.8)
			draw_line(center + Vector2(5 * rendered_facing, 1), brow_hand, cloth.lightened(0.06), 2.0)
			draw_circle(brow_hand, 1.8, accent.lightened(0.12))
			var sweat := _load_emote_texture("res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_drop.png")
			if sweat != null:
				var sweat_rect := Rect2(head_center + Vector2(10 * rendered_facing, -15 + abs(idle_wave) * 2.0), Vector2(10, 10))
				draw_texture_rect(sweat, sweat_rect, false, Color(1, 1, 1, 0.72))
			_draw_breath_puff(head_center + Vector2(7 * rendered_facing, 1), weight * 0.9)
		"ledger":
			var ledger_center := center + Vector2(10 * rendered_facing, 3 + idle_wave * 0.5)
			_draw_role_prop_icon("ledger", ledger_center, 15.0)
			draw_line(center + Vector2(4 * rendered_facing, -1), ledger_center + Vector2(-2 * rendered_facing, -3), accent.lightened(0.1), 1.7)
		"coin":
			var coin_hand := center + Vector2((10.0 + idle_wave * 1.8) * rendered_facing, -4.0)
			draw_line(center + Vector2(5 * rendered_facing, 0), coin_hand, accent.lightened(0.08), 1.9)
			_draw_role_prop_icon("coin", coin_hand + Vector2(2 * rendered_facing, -6 - abs(idle_wave) * 1.8), 12.0)
		"megaphone":
			var megaphone_tip := head_center + Vector2(10 * rendered_facing, 1 + idle_wave * 0.5)
			draw_line(center + Vector2(5 * rendered_facing, 0), megaphone_tip, cloth.lightened(0.08), 2.0)
			draw_colored_polygon(PackedVector2Array([
				megaphone_tip + Vector2(0, -2),
				megaphone_tip + Vector2(8 * rendered_facing, -5),
				megaphone_tip + Vector2(8 * rendered_facing, 3)
			]), accent.lightened(0.14))


func _draw_role_walk(center: Vector2, head_center: Vector2, accent: Color, cloth: Color, walk_weight: float) -> void:
	if walk_weight < 0.18:
		return
	match str(visual_profile.get("prop", "gesture")):
		"paper":
			var notebook_center := center + Vector2(10 * rendered_facing, 0)
			_draw_role_prop_icon("paper", notebook_center, 13.0)
			var pen_hand := center + Vector2((6.0 + sin(wobble_time * 6.4 + gesture_phase) * 1.4) * rendered_facing, -2.0)
			draw_line(center + Vector2(4 * rendered_facing, -1), pen_hand, accent.darkened(0.08), 1.6)
			draw_line(pen_hand, notebook_center + Vector2(-2 * rendered_facing, -2), Color("f5e4b8"), 1.0)
		"cane":
			var cane_top := center + Vector2(8 * rendered_facing, -4)
			var cane_bottom := center + Vector2(9 * rendered_facing, 18 + abs(sin(wobble_time * 3.0)) * 1.5)
			draw_line(cane_top, cane_bottom, BODY_OUTLINE, 2.0)
			draw_arc(cane_top + Vector2(-1 * rendered_facing, -3), 2.7, 0.0, PI, 8, BODY_OUTLINE, 1.2)


func _draw_breath_puff(origin: Vector2, alpha_scale: float) -> void:
	var cloud := _load_emote_texture("res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_cloud.png")
	if cloud == null:
		return
	var puff_size := lerpf(9.0, 13.0, clampf(alpha_scale, 0.0, 1.0))
	var puff_rect := Rect2(origin + Vector2(4 * rendered_facing, -5 - abs(sin(wobble_time * 2.8 + gesture_phase)) * 2.0), Vector2.ONE * puff_size)
	draw_texture_rect(cloud, puff_rect, false, Color(1, 1, 1, 0.25 + alpha_scale * 0.35))


func _draw_emote_icon(head_center: Vector2) -> void:
	var path := _emote_icon_path()
	if path.is_empty():
		return
	var texture := _load_emote_texture(path)
	if texture == null:
		return
	var strength := clampf(max(max(speech_impulse * 0.95, focus_impulse * 0.75), max(observer_attention * 0.85, bubble_alpha * 0.35)), 0.0, 1.0)
	if strength < 0.08:
		return
	var float_offset := sin(wobble_time * 3.2 + gesture_phase) * 2.4
	var icon_size := lerpf(12.0, 20.0, strength)
	var icon_center := head_center + Vector2((18.0 + strength * 5.0) * rendered_facing, -24.0 - float_offset)
	var rect := Rect2(icon_center - Vector2.ONE * (icon_size * 0.5), Vector2.ONE * icon_size)
	var shadow_rect: Rect2 = Rect2(rect.position + Vector2(2, 2), rect.size)
	draw_rect(shadow_rect, Color(0, 0, 0, 0.14 * strength), true)
	draw_texture_rect(texture, rect, false, Color(1, 1, 1, 0.5 + strength * 0.45))


func _emote_icon_path() -> String:
	var mood := str(npc_data.get("mood", ""))
	if not emotion_role.is_empty():
		match emotion_role:
			"puzzled":
				return "res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_question.png"
			"startled":
				return "res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_exclamations.png"
			"scoff":
				return "res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_anger.png"
			"hurry":
				return "res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_alert.png"
	if social_role == "speaker":
		match str(visual_profile.get("prop", "gesture")):
			"coin":
				return "res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_cash.png"
			"paper", "ledger":
				return "res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_idea.png"
			"megaphone":
				return "res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_exclamations.png"
		return "res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_dots3.png"
	if social_role == "listener":
		if mood == "anxious":
			return "res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_swirl.png"
		return "res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_question.png"
	match mood:
		"excited":
			return "res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_star.png"
		"hopeful":
			return "res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_heart.png"
		"defiant":
			return "res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_anger.png"
		"anxious":
			return "res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_alert.png"
		"tired":
			return "res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_sleep.png"
	match str(visual_profile.get("prop", "gesture")):
		"coin":
			return "res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_cash.png"
		"paper", "ledger":
			return "res://assets/vendor/kenney_emotes_pack/PNG/Pixel/Style 1/emote_idea.png"
	return ""


func _load_emote_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if emote_texture_cache.has(path):
		return emote_texture_cache[path]
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		return null
	var texture := ImageTexture.create_from_image(image)
	emote_texture_cache[path] = texture
	return texture


func _sprite_meta() -> Dictionary:
	var portrait_meta := _custom_portrait_meta()
	if not portrait_meta.is_empty():
		return portrait_meta
	var sprite_key := str(visual_profile.get("sprite_key", "base"))
	return ANIMAL_SPRITES.get(sprite_key, ANIMAL_SPRITES["base"])


func _sprite_frame_index(frame_count: int, moving: bool) -> int:
	if frame_count <= 1:
		return 0
	if moving:
		return int(fposmod(wobble_time * (6.8 + float(visual_profile.get("pace", 0.0))), frame_count))
	if speech_impulse > 0.12 or speech_blend > 0.15:
		return min(2, frame_count - 1) if sin(speech_phase) >= 0.0 else min(1, frame_count - 1)
	return int(fposmod(wobble_time * (1.6 + float(visual_profile.get("idle_rate", 0.0))), min(frame_count, 4)))


func _sprite_row_for_direction(direction: String) -> int:
	match direction:
		"up":
			return 0
		"left":
			return 1
		"right":
			return 3
		_:
			return 2


func _sprite_modulate() -> Color:
	if _uses_custom_portrait():
		return Color.WHITE
	var modulate := Color.WHITE
	match str(npc_data.get("mood", "")):
		"anxious":
			modulate = Color("f0d7cd")
		"excited":
			modulate = Color("f4e2bf")
		"defiant":
			modulate = Color("e7d2c3")
		"hopeful":
			modulate = Color("dde7ca")
		"tired":
			modulate = Color("d8d0c2")
	if str(npc_data.get("class", "")) in ["\u5173\u952e\u89d2\u8272", "\u7279\u6b8a\u89d2\u8272"]:
		modulate = modulate.lightened(0.06)
	return modulate


func _load_sprite_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if sprite_texture_cache.has(path):
		return sprite_texture_cache[path]
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		return null
	var texture := ImageTexture.create_from_image(image)
	sprite_texture_cache[path] = texture
	return texture


func _custom_portrait_meta() -> Dictionary:
	var idle_path := str(visual_profile.get("portrait_idle_path", ""))
	if idle_path.is_empty():
		return {}
	var move_path := str(visual_profile.get("portrait_move_path", idle_path))
	if not FileAccess.file_exists(ProjectSettings.globalize_path(move_path)):
		move_path = idle_path
	return {
		"idle_path": idle_path,
		"move_path": move_path,
		"frame": Vector2i(128, 128),
		"idle_frames": 4,
		"move_frames": 8,
		"scale": 0.68,
		"ground_offset": 26.0,
		"family": "portrait"
	}


func _uses_custom_portrait() -> bool:
	return not _custom_portrait_meta().is_empty()


func _draw_species_tail(center: Vector2, accent: Color, cloth: Color) -> void:
	if str(visual_profile.get("sprite_family", "")) in ["square", "portrait"]:
		return
	match str(visual_profile.get("tail", "none")):
		"fox":
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(-12 * rendered_facing, -3),
				center + Vector2(-24 * rendered_facing, 1),
				center + Vector2(-16 * rendered_facing, 12)
			]), accent.darkened(0.12))
		"squirrel":
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(-12 * rendered_facing, -5),
				center + Vector2(-25 * rendered_facing, -18),
				center + Vector2(-20 * rendered_facing, 4),
				center + Vector2(-14 * rendered_facing, 14)
			]), accent.lightened(0.04))
		"seal":
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(-10 * rendered_facing, 10),
				center + Vector2(-18 * rendered_facing, 15),
				center + Vector2(-12 * rendered_facing, 18)
			]), cloth.darkened(0.1))
		"lizard":
			draw_line(center + Vector2(-9 * rendered_facing, 7), center + Vector2(-22 * rendered_facing, 13), accent.darkened(0.2), 3.2)
		"armadillo":
			draw_arc(center + Vector2(-10 * rendered_facing, 2), 7.0, PI * 0.1, PI * 1.1, 10, accent.darkened(0.22), 2.2)


func _draw_torso(center: Vector2, cloth: Color, accent: Color, tilt: float, breathe: float) -> void:
	var shoulder: float = float(visual_profile.get("shoulder", 13.0)) + abs(stance_lean) * 1.4
	var waist: float = float(visual_profile.get("waist", 10.0))
	var hem: float = float(visual_profile.get("hem", 14.0))
	var height: float = float(visual_profile.get("height", 31.0))
	var torso := PackedVector2Array([
		center + Vector2(-shoulder + tilt * 6.0, -17),
		center + Vector2(shoulder + tilt * 6.0, -17),
		center + Vector2(waist, 1),
		center + Vector2(hem, height),
		center + Vector2(-hem, height),
		center + Vector2(-waist, 1)
	])
	draw_colored_polygon(torso, cloth)
	_draw_outline(torso, BODY_OUTLINE, 2.0, true)

	var trim := accent.lightened(0.05)
	draw_line(center + Vector2(0, -16), center + Vector2(0, height), trim, 2.0)
	draw_line(center + Vector2(-shoulder + 2, 0), center + Vector2(shoulder - 2, 0), BODY_OUTLINE, 1.2)

	match str(visual_profile.get("garment", "tunic")):
		"apron":
			draw_rect(Rect2(center + Vector2(-5, -2), Vector2(10, height - 2)), accent.lightened(0.18), true)
			draw_rect(Rect2(center + Vector2(-5, -2), Vector2(10, height - 2)), BODY_OUTLINE, false, 1.0)
		"patched":
			draw_rect(Rect2(center + Vector2(-7, 4), Vector2(5, 5)), accent.darkened(0.2), true)
			draw_rect(Rect2(center + Vector2(2, 12), Vector2(4, 6)), accent.lightened(0.12), true)
		"vest":
			draw_rect(Rect2(center + Vector2(-9, -8), Vector2(18, 16)), accent.darkened(0.08), true)
			draw_line(center + Vector2(-9, -8), center + Vector2(-9, 8), BODY_OUTLINE, 1.2)
			draw_line(center + Vector2(9, -8), center + Vector2(9, 8), BODY_OUTLINE, 1.2)
		"coat":
			draw_line(center + Vector2(-9, -10), center + Vector2(-13, 16), accent.darkened(0.18), 3.2)
			draw_line(center + Vector2(9, -10), center + Vector2(13, 16), accent.darkened(0.18), 3.2)
		"cape":
			var cape := PackedVector2Array([
				center + Vector2(-12, -14),
				center + Vector2(12, -14),
				center + Vector2(18, 12),
				center + Vector2(8, height),
				center + Vector2(-8, height),
				center + Vector2(-18, 12)
			])
			draw_colored_polygon(cape, accent.darkened(0.22))
			_draw_outline(cape, BODY_OUTLINE, 1.6, true)
		"robe":
			draw_rect(Rect2(center + Vector2(-6, -14), Vector2(12, height + 8)), accent.lightened(0.08), false, 1.4)

	if bool(visual_profile.get("neck_scarf", false)):
		_draw_collar(center.y - 20, accent)
	if bool(visual_profile.get("satchel", false)):
		_draw_satchel(center + Vector2(11 * rendered_facing, 4), accent)
	if bool(visual_profile.get("shell_back", false)):
		draw_circle(center + Vector2(-9 * rendered_facing, -2), 7.5, accent.darkened(0.26))
		draw_circle(center + Vector2(-9 * rendered_facing, -2), 4.4, accent.lightened(0.12))


func _draw_back_arm(center: Vector2, stride: float, cloth: Color, skin: Color, speaker_weight: float, listener_weight: float) -> void:
	var swing := stride * 0.45 - 1.0 - speaker_weight * 0.8 + listener_weight * 0.35
	_draw_arm(center, -rendered_facing, swing, cloth.darkened(0.12), skin.darkened(0.08), 0.84)


func _draw_front_arm(center: Vector2, stride: float, cloth: Color, skin: Color, accent: Color, speaker_weight: float, listener_weight: float) -> void:
	var social_swing := speaker_weight * 2.4 - listener_weight * 1.1
	_draw_arm(center, rendered_facing, -stride * 0.5 + float(visual_profile.get("reach", 0.0)) + social_swing, cloth, skin, 1.0)
	if listener_weight > 0.0:
		draw_circle(center + Vector2(10 * rendered_facing, 2 - stride * 0.15), 1.4, accent.lightened(0.1))
	if bool(visual_profile.get("wrist_trim", false)):
		draw_circle(center + Vector2(11 * rendered_facing, 4 - stride * 0.2), 1.5, accent.lightened(0.18))


func _draw_arm(center: Vector2, side: float, swing: float, cloth: Color, skin: Color, alpha_scale: float) -> void:
	var shoulder := center + Vector2(9.0 * side, -11.0)
	var elbow := shoulder + Vector2(4.5 * side + swing * 0.2 * side, 8.5 + abs(swing) * 0.18)
	var hand := elbow + Vector2(4.0 * side + swing * 0.35 * side, 8.0 - min(swing, 0.0) * 0.2)
	draw_line(shoulder, elbow, cloth.darkened(0.08), 4.0 * alpha_scale)
	draw_line(elbow, hand, skin, 3.0 * alpha_scale)
	draw_circle(hand, 2.0 * alpha_scale, skin.lightened(0.08))


func _draw_leg(origin: Vector2, gait: float, direction: float, accent: Color) -> void:
	var knee := origin + Vector2(3 * direction, 7 + abs(gait) * 0.22)
	var foot := origin + Vector2(5 * direction + gait * 0.48 * direction, 16 + abs(gait) * 0.34)
	draw_line(origin, knee, accent.darkened(0.35), 3.0)
	draw_line(knee, foot, accent.darkened(0.28), 3.0)
	draw_line(foot + Vector2(-3, 1.4), foot + Vector2(3, 1.4), Color("221710"), 1.2)


func _draw_satchel(origin: Vector2, accent: Color) -> void:
	draw_line(origin + Vector2(-5 * rendered_facing, -8), origin + Vector2(0, -1), Color("4b3324"), 1.8)
	draw_rect(Rect2(origin + Vector2(-5, -1), Vector2(10, 9)), accent.darkened(0.18), true)
	draw_rect(Rect2(origin + Vector2(-5, -1), Vector2(10, 9)), Color("2d1b12"), false, 1.0)
	draw_line(origin + Vector2(-5, 3), origin + Vector2(5, 3), Color("c7ad7d"), 1.0)


func _draw_collar(y_offset: float, accent: Color) -> void:
	var collar := PackedVector2Array([
		Vector2(-7, y_offset),
		Vector2(0, y_offset - 5),
		Vector2(7, y_offset),
		Vector2(3, y_offset + 6),
		Vector2(-3, y_offset + 6)
	])
	draw_colored_polygon(collar, accent.lightened(0.18))
	_draw_outline(collar, BODY_OUTLINE, 1.2, true)


func _draw_head(center: Vector2, look: Vector2, blink_closed: bool, accent: Color, talk_open: float) -> void:
	var head_points := PackedVector2Array()
	var profile_x: float = 10.8 + abs(look.x) * 0.8
	for step in range(18):
		var angle := TAU * float(step) / 18.0
		head_points.append(center + Vector2(cos(angle) * profile_x, sin(angle) * 9.6))
	draw_colored_polygon(head_points, _skin_color())
	_draw_outline(head_points, BODY_OUTLINE, 2.0, true)
	_draw_hat(center, accent)
	draw_circle(center + Vector2(5.2 * look.x, -5), 2.0, Color("e8d7b5"))
	var eye := center + Vector2(3.1 * look.x, -2.5)
	if blink_closed:
		draw_line(eye + Vector2(-2, 0), eye + Vector2(2, 0), BODY_OUTLINE, 1.4)
	else:
		draw_circle(eye, 1.2, BODY_OUTLINE)
	var mouth_y := 3.2 + talk_open * 1.5
	draw_line(center + Vector2(-2, mouth_y), center + Vector2(3, 3.5 + talk_open * 1.2), accent.darkened(0.5), 1.1 + talk_open * 0.5)


func _draw_hat(center: Vector2, accent: Color) -> void:
	match str(visual_profile.get("hat", "none")):
		"cap":
			draw_rect(Rect2(center + Vector2(-6, -16), Vector2(12, 4)), accent.darkened(0.05), true)
			draw_rect(Rect2(center + Vector2(-2, -12), Vector2(8, 3)), accent.lightened(0.12), true)
		"hood":
			var hood := PackedVector2Array([
				center + Vector2(-9, -13),
				center + Vector2(0, -20),
				center + Vector2(10, -12),
				center + Vector2(7, -4),
				center + Vector2(-7, -4)
			])
			draw_colored_polygon(hood, accent.darkened(0.12))
			_draw_outline(hood, BODY_OUTLINE, 1.4, true)
		"brim":
			draw_line(center + Vector2(-9, -13), center + Vector2(9, -13), BODY_OUTLINE, 2.2)
			draw_rect(Rect2(center + Vector2(-4, -18), Vector2(8, 5)), accent.darkened(0.08), true)
		"circlet":
			draw_arc(center + Vector2(0, -10), 7.0, PI * 1.05, PI * 1.95, 12, accent.lightened(0.18), 2.2)


func _draw_species_detail(center: Vector2, look: Vector2, accent: Color) -> void:
	match str(visual_profile.get("ears", "round")):
		"long":
			draw_line(center + Vector2(-3, -8), center + Vector2(-7, -23), accent.darkened(0.2), 2.3)
			draw_line(center + Vector2(3, -8), center + Vector2(7, -23), accent.darkened(0.2), 2.3)
		"pointed":
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(-7, -8), center + Vector2(-12, -18), center + Vector2(-2, -11)
			]), accent)
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(7, -8), center + Vector2(12, -18), center + Vector2(2, -11)
			]), accent)
		"feather":
			draw_line(center + Vector2(0, -11), center + Vector2(4, -21), accent.darkened(0.14), 2.0)
			draw_line(center + Vector2(-2, -10), center + Vector2(-4, -19), accent.darkened(0.08), 1.6)
		"horn":
			draw_arc(center + Vector2(-5, -10), 4.0, PI * 1.0, PI * 1.8, 8, accent.darkened(0.24), 2.0)
			draw_arc(center + Vector2(5, -10), 4.0, PI * 1.2, PI * 2.0, 8, accent.darkened(0.24), 2.0)
		_:
			draw_circle(center + Vector2(-6, -10), 1.7, accent)
			draw_circle(center + Vector2(6, -10), 1.7, accent)

	match str(visual_profile.get("muzzle", "none")):
		"beak":
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(5 * rendered_facing, -1),
				center + Vector2(13 * rendered_facing, 1),
				center + Vector2(5 * rendered_facing, 3)
			]), accent.lightened(0.14))
		"snout":
			draw_rect(Rect2(center + Vector2(4 * rendered_facing, -1), Vector2(6, 4)), accent.lightened(0.1), true)
		"whisker":
			draw_line(center + Vector2(4 * rendered_facing, 2), center + Vector2(11 * rendered_facing, 0), BODY_OUTLINE, 1.1)
			draw_line(center + Vector2(4 * rendered_facing, 4), center + Vector2(10 * rendered_facing, 5), BODY_OUTLINE, 1.1)


func _draw_role_prop(origin: Vector2, bob: float, accent: Color) -> void:
	match str(visual_profile.get("prop", "gesture")):
		"paper":
			if not _draw_role_prop_icon("paper", origin + Vector2(11 * rendered_facing, -1 + bob), 15.0):
				draw_rect(Rect2(origin + Vector2(7 * rendered_facing, -4 + bob), Vector2(10, 8)), Color("f0dfb0"), true)
				draw_rect(Rect2(origin + Vector2(7 * rendered_facing, -4 + bob), Vector2(10, 8)), BODY_OUTLINE, false, 1.2)
		"tool":
			if not _draw_role_prop_icon("tool", origin + Vector2(-12 * rendered_facing, -6 + bob), 17.0):
				draw_line(origin + Vector2(-6 * rendered_facing, 0 + bob), origin + Vector2(-14 * rendered_facing, -10 + bob), accent.darkened(0.2), 2.0)
				draw_circle(origin + Vector2(-14 * rendered_facing, -10 + bob), 3.0, accent)
		"coin":
			if not _draw_role_prop_icon("coin", origin + Vector2(11 * rendered_facing, 2 + bob), 13.0):
				draw_circle(origin + Vector2(10 * rendered_facing, 2 + bob), 3.0, Color("c9a34c"))
				draw_circle(origin + Vector2(10 * rendered_facing, 2 + bob), 1.2, Color("f2e1b4"))
		"cane":
			draw_line(origin + Vector2(11 * rendered_facing, -6 + bob), origin + Vector2(12 * rendered_facing, 16 + bob), BODY_OUTLINE, 2.0)
			draw_arc(origin + Vector2(10 * rendered_facing, -9 + bob), 3.0, 0.0, PI, 8, BODY_OUTLINE, 1.4)
		"megaphone":
			draw_colored_polygon(PackedVector2Array([
				origin + Vector2(8 * rendered_facing, 0 + bob),
				origin + Vector2(16 * rendered_facing, -3 + bob),
				origin + Vector2(16 * rendered_facing, 5 + bob)
			]), accent.lightened(0.12))
		"ledger":
			if not _draw_role_prop_icon("ledger", origin + Vector2(12 * rendered_facing, 2 + bob), 16.0):
				draw_rect(Rect2(origin + Vector2(8 * rendered_facing, -4 + bob), Vector2(9, 12)), accent.darkened(0.16), true)
				draw_line(origin + Vector2(12 * rendered_facing, -4 + bob), origin + Vector2(12 * rendered_facing, 8 + bob), Color("d9c18d"), 1.0)
		_:
			draw_line(origin + Vector2(8 * rendered_facing, 2 + bob), origin + Vector2(13 * rendered_facing, 8 + bob), accent.darkened(0.2), 1.6)


func _draw_commute_carry_prop(origin: Vector2, bob: float, accent: Color, cloth: Color) -> void:
	var carry_prop: String = str(visual_profile.get("carry_prop", ""))
	var carry_alpha: float = float(visual_profile.get("carry_alpha", 0.0))
	if carry_prop.is_empty() or carry_alpha <= 0.04:
		return
	var tint: Color = Color(1.0, 1.0, 1.0, clampf(carry_alpha, 0.0, 1.0))
	match carry_prop:
		"ledger":
			if not _draw_role_prop_icon("ledger", origin + Vector2(16 * rendered_facing, 4 + bob), 15.0):
				draw_rect(Rect2(origin + Vector2(10 * rendered_facing, -2 + bob), Vector2(10, 12)), accent.darkened(0.12) * tint, true)
				draw_line(origin + Vector2(14 * rendered_facing, -2 + bob), origin + Vector2(14 * rendered_facing, 10 + bob), Color(0.86, 0.78, 0.62, carry_alpha), 1.0)
		"tool":
			if not _draw_role_prop_icon("tool", origin + Vector2(-14 * rendered_facing, -2 + bob), 15.0):
				draw_line(origin + Vector2(-6 * rendered_facing, 0 + bob), origin + Vector2(-14 * rendered_facing, -10 + bob), cloth.darkened(0.18) * tint, 2.0)
				draw_circle(origin + Vector2(-14 * rendered_facing, -10 + bob), 3.0, accent * tint)
		"satchel":
			draw_line(origin + Vector2(0, -6 + bob), origin + Vector2(10 * rendered_facing, 8 + bob), Color(0.34, 0.24, 0.16, 0.76 * carry_alpha), 1.8)
			draw_rect(Rect2(origin + Vector2(6 * rendered_facing, 6 + bob), Vector2(12, 10)), accent.darkened(0.22) * tint, true)
			draw_rect(Rect2(origin + Vector2(6 * rendered_facing, 6 + bob), Vector2(12, 10)), Color(0.18, 0.12, 0.08, 0.68 * carry_alpha), false, 1.0)
		"breakfast":
			draw_circle(origin + Vector2(12 * rendered_facing, 5 + bob), 6.0, Color(0.78, 0.72, 0.58, 0.72 * carry_alpha))
			draw_rect(Rect2(origin + Vector2(18 * rendered_facing, 1 + bob), Vector2(10, 4)), Color(0.78, 0.64, 0.42, 0.7 * carry_alpha), true)
			draw_line(origin + Vector2(8 * rendered_facing, -2 + bob), origin + Vector2(18 * rendered_facing, 8 + bob), Color(0.96, 0.88, 0.7, 0.62 * carry_alpha), 1.0)


func _draw_role_prop_icon(prop: String, center: Vector2, size: float) -> bool:
	var path := str(ROLE_PROP_ICON_PATHS.get(prop, ""))
	if path.is_empty():
		return false
	var texture := _load_emote_texture(path)
	if texture == null:
		return false
	var rect := Rect2(center - Vector2.ONE * (size * 0.5), Vector2.ONE * size)
	var shadow_rect: Rect2 = Rect2(rect.position + Vector2(2, 2), rect.size)
	draw_rect(shadow_rect, Color(0, 0, 0, 0.12), true)
	draw_texture_rect(texture, rect, false)
	return true


func _build_visual_profile(data: Dictionary) -> Dictionary:
	var profile := {
		"height": 30.0,
		"shoulder": 12.0,
		"waist": 9.0,
		"hem": 13.0,
		"garment": "tunic",
		"hat": "none",
		"prop": "gesture",
		"tail": "none",
		"ears": "round",
		"muzzle": "none",
		"bubble_height": 92.0,
		"pace": 0.0,
		"restless": 0.0,
		"reach": 0.0,
		"neck_scarf": false,
		"satchel": false,
		"shell_back": false,
		"wrist_trim": false,
		"blink_bias": 0.0,
		"speech_rate": 0.0,
		"travel_rate": 2.4,
		"turn_rate": 7.0,
		"walk_blend_rate": 4.0,
		"settle_rate": 4.2,
		"stride_scale": 1.0,
		"labor_breath": 0.0,
		"sprite_family": "square",
		"sprite_key": _npc_sprite_key(data),
		"portrait_idle_path": "",
		"portrait_move_path": "",
		"sprite_scale_bias": 0.0,
		"posture_phase": _variant_unit(str(data.get("id", "")), 0) * TAU,
		"shoulder_offset": _variant_centered(str(data.get("id", "")), 1) * 8.0,
		"head_bob_bias": _variant_centered(str(data.get("id", "")), 2),
		"idle_rate": _variant_unit(str(data.get("id", "")), 3) * 0.45,
		"stride_rate": _variant_centered(str(data.get("id", "")), 4) * 0.55,
		"stride_height": _variant_centered(str(data.get("id", "")), 5) * 1.2,
		"breath_rate": _variant_centered(str(data.get("id", "")), 6) * 0.3,
		"look_bias": _variant_centered(str(data.get("id", "")), 7),
		"crowd_phase": _variant_unit(str(data.get("id", "")), 8) * TAU,
		"gesture_phase": _variant_unit(str(data.get("id", "")), 9) * TAU
	}
	profile["carry_prop"] = str(data.get("carry_prop", ""))
	profile["carry_alpha"] = float(data.get("carry_alpha", 0.0))
	if str(profile["carry_prop"]) == "satchel":
		profile["satchel"] = true

	match str(data.get("role", "")):
		"\u5de5\u4eba":
			profile["garment"] = "apron"
			profile["prop"] = "tool"
			profile["pace"] = 0.4
			profile["shoulder"] = 13.0
			profile["labor_breath"] = 0.75
			profile["settle_rate"] = 3.2
		"\u4e34\u65f6\u5de5":
			profile["garment"] = "patched"
			profile["satchel"] = true
			profile["neck_scarf"] = true
			profile["restless"] = 0.8
			profile["pace"] = 0.65
			profile["speech_rate"] = 1.0
			profile["sprite_scale_bias"] = -0.06
			profile["labor_breath"] = 0.9
			profile["settle_rate"] = 2.9
		"\u5e97\u4e3b":
			profile["garment"] = "vest"
			profile["hat"] = "cap"
			profile["satchel"] = true
			profile["wrist_trim"] = true
			profile["travel_rate"] = 2.8
			profile["stride_scale"] = 0.86
		"\u8bb0\u8005":
			profile["garment"] = "coat"
			profile["hat"] = "brim"
			profile["prop"] = "paper"
			profile["reach"] = 2.0
			profile["speech_rate"] = 1.3
			profile["travel_rate"] = 3.4
			profile["turn_rate"] = 7.8
			profile["stride_scale"] = 0.92
		"\u8001\u677f":
			profile["garment"] = "cape"
			profile["hat"] = "circlet"
			profile["prop"] = "cane"
			profile["shoulder"] = 14.5
			profile["height"] = 32.0
			profile["sprite_scale_bias"] = 0.06
			profile["travel_rate"] = 2.4
			profile["turn_rate"] = 4.8
			profile["stride_scale"] = 0.68
			profile["settle_rate"] = 2.4
		"\u6295\u673a\u8005":
			profile["garment"] = "coat"
			profile["hat"] = "hood"
			profile["prop"] = "coin"
			profile["restless"] = 1.0
			profile["pace"] = 0.9
			profile["speech_rate"] = 1.1
		"\u5de5\u4f1a\u9886\u8896":
			profile["garment"] = "cape"
			profile["prop"] = "megaphone"
			profile["neck_scarf"] = true
			profile["shoulder"] = 15.0
			profile["speech_rate"] = 1.5
		"\u4ee3\u7406\u4eba":
			profile["garment"] = "coat"
			profile["hat"] = "hood"
			profile["prop"] = "paper"
			profile["reach"] = 1.4
		"\u94f6\u884c\u7ecf\u7406":
			profile["garment"] = "robe"
			profile["hat"] = "circlet"
			profile["prop"] = "ledger"
			profile["height"] = 34.0
			profile["sprite_scale_bias"] = 0.04
			profile["travel_rate"] = 2.6
			profile["stride_scale"] = 0.74
			profile["turn_rate"] = 5.3

	match str(data.get("species", "")):
		"\u5154\u5b50", "\u9a74":
			profile["ears"] = "long"
			profile["height"] = float(profile["height"]) + 1.0
			profile["sprite_scale_bias"] = float(profile["sprite_scale_bias"]) - 0.03
		"\u72fc", "\u72d0\u72f8", "\u9f2c", "\u6d63\u718a":
			profile["ears"] = "pointed"
			profile["muzzle"] = "snout"
			profile["tail"] = "fox" if str(data.get("species", "")) == "\u72d0\u72f8" else "none"
		"\u4e4c\u9e26", "\u767d\u9e6d", "\u732b\u5934\u9e70":
			profile["ears"] = "feather"
			profile["muzzle"] = "beak"
		"\u5c71\u7f8a":
			profile["ears"] = "horn"
			profile["muzzle"] = "snout"
			profile["sprite_key"] = "base"
		"\u8001\u9f20", "\u677e\u9f20":
			profile["ears"] = "round"
			profile["muzzle"] = "whisker"
			if str(data.get("species", "")) == "\u677e\u9f20":
				profile["tail"] = "squirrel"
			profile["sprite_scale_bias"] = float(profile["sprite_scale_bias"]) - 0.05
		"\u6d77\u8c79":
			profile["tail"] = "seal"
		"\u8725\u8734":
			profile["tail"] = "lizard"
			profile["muzzle"] = "snout"
		"\u72b0\u72f3":
			profile["tail"] = "armadillo"
			profile["shell_back"] = true
			profile["sprite_scale_bias"] = float(profile["sprite_scale_bias"]) - 0.02
		"\u91ce\u732a", "\u737e", "\u718a":
			profile["muzzle"] = "snout"
			profile["shoulder"] = float(profile["shoulder"]) + 1.0

	match str(data.get("class", "")):
		"\u4e2d\u5c42":
			profile["wrist_trim"] = true
			profile["bubble_height"] = 96.0
			profile["blink_bias"] = -0.08
		"\u5173\u952e\u89d2\u8272", "\u7279\u6b8a\u89d2\u8272":
			profile["height"] = float(profile["height"]) + 2.0
			profile["shoulder"] = float(profile["shoulder"]) + 1.2
			profile["bubble_height"] = 100.0
			profile["hat"] = "circlet" if str(profile["hat"]) == "none" else profile["hat"]
			profile["blink_bias"] = -0.12
			profile["sprite_scale_bias"] = float(profile["sprite_scale_bias"]) + 0.04

	match str(data.get("activity", "")):
		"commuting":
			profile["pace"] = float(profile["pace"]) + 0.8
			profile["restless"] = float(profile["restless"]) + 0.3
		"returning":
			profile["pace"] = float(profile["pace"]) + 0.4
		"assembling", "meeting", "gathering":
			profile["pace"] = float(profile["pace"]) + 0.26
			profile["restless"] = float(profile["restless"]) + 0.18
		"protesting", "responding":
			profile["pace"] = float(profile["pace"]) + 0.42
			profile["restless"] = float(profile["restless"]) + 0.28
		"negotiating", "watching":
			profile["restless"] = float(profile["restless"]) + 0.12
		"home":
			profile["restless"] = max(0.0, float(profile["restless"]) - 0.25)

	var portrait_paths := _portrait_paths_for_id(str(data.get("id", "")))
	if not portrait_paths.is_empty():
		profile["portrait_idle_path"] = str(portrait_paths.get("idle_path", ""))
		profile["portrait_move_path"] = str(portrait_paths.get("move_path", ""))
		profile["sprite_family"] = "portrait"
		profile["sprite_scale_bias"] = max(float(profile["sprite_scale_bias"]), -0.02)

	return profile


func _speech_fill_color() -> Color:
	match str(npc_data.get("mood", "")):
		"anxious":
			return Color("f0d3c1")
		"excited":
			return Color("f2dfb1")
		"defiant":
			return Color("e8cfbf")
		"hopeful":
			return Color("e0e2bf")
		"tired":
			return Color("ded1ba")
	return Color("f3e1b5")


func _skin_color() -> Color:
	match str(npc_data.get("species", "")):
		"\u4e4c\u9e26", "\u732b\u5934\u9e70":
			return Color("c9bfad")
		"\u767d\u9e6d":
			return Color("e6dece")
		"\u8725\u8734":
			return Color("b8c28e")
		"\u6d77\u8c79":
			return Color("d4c5b3")
	return Color("dbc79f")


func _body_color() -> Color:
	match str(npc_data.get("mood", "")):
		"anxious":
			return Color("8f5c4c")
		"excited":
			return Color("a8823c")
		"defiant":
			return Color("8c4a3d")
		"hopeful":
			return Color("718744")
		"wary":
			return Color("6f6250")
		"tired":
			return Color("7f6a52")
	return Color("7a6857")


func _accent_color() -> Color:
	match str(npc_data.get("class", "")):
		"\u5e95\u5c42":
			return Color("7b5936")
		"\u4e2d\u5c42":
			return Color("6b7d42")
		"\u5173\u952e\u89d2\u8272", "\u7279\u6b8a\u89d2\u8272":
			return Color("ab8540")
	return Color("7b5936")


func _cloth_color(base_color: Color) -> Color:
	return base_color.lightened(0.13)


func _activity_text(value: String) -> String:
	match value:
		"working":
			return "\u4e0a\u5de5"
		"home":
			return "\u56de\u5bb6"
		"returning":
			return "\u6536\u5de5"
		"commuting":
			return "\u8d76\u8def"
		"assembling":
			return "\u96c6\u7ed3"
		"meeting":
			return "\u52a8\u5458"
		"protesting":
			return "\u6297\u8bae"
		"gathering":
			return "\u805a\u96c6"
		"responding":
			return "\u63a7\u573a"
		"negotiating":
			return "\u8c08\u5224"
		"watching":
			return "\u56f4\u89c2"
	return "\u95f2\u6643"


func _stance_bias() -> float:
	match str(npc_data.get("stance", "")):
		"\u6fc0\u8fdb":
			return 0.55
		"\u62b1\u56e2":
			return 0.35
		"\u51b7\u7b11":
			return -0.22
		"\u8c28\u614e":
			return -0.42
		"\u89c2\u671b":
			return -0.12
		"\u73b0\u5b9e":
			return 0.08
	return 0.0


func _npc_sprite_key(data: Dictionary) -> String:
	match str(data.get("class", "")):
		"\u5173\u952e\u89d2\u8272", "\u7279\u6b8a\u89d2\u8272":
			return "hero"
	match str(data.get("role", "")):
		"\u94f6\u884c\u7ecf\u7406", "\u8001\u677f", "\u4ee3\u7406\u4eba", "\u8bb0\u8005":
			return "hero"
		"\u5de5\u4eba", "\u4e34\u65f6\u5de5":
			return "monster"
		"\u5de5\u4f1a\u9886\u8896":
			return "skeleton"
	var keys := ["base", "hero", "monster", "skeleton"]
	var total := 0
	for ch in str(data.get("id", "")).to_utf8_buffer():
		total += int(ch)
	return keys[total % keys.size()]


func _portrait_paths_for_id(npc_id: String) -> Dictionary:
	if npc_id.is_empty():
		return {}
	var idle_path := "%s/%s_idle.png" % [PORTRAIT_BASE_PATH, npc_id]
	if not FileAccess.file_exists(ProjectSettings.globalize_path(idle_path)):
		return {}
	var move_path := "%s/%s_move.png" % [PORTRAIT_BASE_PATH, npc_id]
	if not FileAccess.file_exists(ProjectSettings.globalize_path(move_path)):
		move_path = idle_path
	return {
		"idle_path": idle_path,
		"move_path": move_path,
	}


func _direction_name_for_vector(value: Vector2) -> String:
	if abs(value.x) > abs(value.y):
		return "right" if value.x >= 0.0 else "left"
	return "up" if value.y < 0.0 else "down"


func _variant_unit(seed: String, salt: int) -> float:
	var total := 0
	var buffer := ("%s#%s" % [seed, salt]).to_utf8_buffer()
	for ch in buffer:
		total += int(ch)
	return fposmod(float(total) * 0.173, 1.0)


func _variant_centered(seed: String, salt: int) -> float:
	return _variant_unit(seed, salt) * 2.0 - 1.0


func _draw_shadow(center: Vector2, radii: Vector2, alpha: float) -> void:
	var points := PackedVector2Array()
	for step in range(20):
		var angle := TAU * float(step) / 20.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, Color(0, 0, 0, alpha))


func _draw_outline(points: PackedVector2Array, color_value: Color, width: float, closed: bool) -> void:
	if closed:
		var closed_points := PackedVector2Array(points)
		closed_points.append(points[0])
		draw_polyline(closed_points, color_value, width)
	else:
		draw_polyline(points, color_value, width)
