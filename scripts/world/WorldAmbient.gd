extends Node2D
class_name WorldAmbient

const WorldLayout = preload("res://scripts/world/WorldLayout.gd")
const REDRAW_INTERVAL := 0.25
const WORLD_RECT := WorldLayout.WORLD_RECT
const DISTRICT_RECTS := WorldLayout.DISTRICT_RECTS
const HOUSE_IDS := ["slum_house", "dock_house", "factory_house", "exchange_house"]

var time_passed := 0.0
var time_period := "day"
var light_level := 1.0
var house_states: Dictionary = {}
var redraw_accumulator := 0.0


func _process(delta: float) -> void:
	time_passed += delta
	redraw_accumulator += delta
	if redraw_accumulator >= REDRAW_INTERVAL:
		redraw_accumulator = 0.0
		queue_redraw()


func set_time_of_day(period: String, level: float) -> void:
	time_period = period
	light_level = clampf(level, 0.2, 1.0)
	redraw_accumulator = 0.0
	queue_redraw()


func set_house_states(states: Dictionary) -> void:
	house_states = states.duplicate(true)
	redraw_accumulator = 0.0
	queue_redraw()


func _draw() -> void:
	_draw_time_wash()
	_draw_district_tint()
	_draw_sky_glow()
	_draw_ground_falloff()
	_draw_house_glow()
	_draw_lantern_pools()


func _draw_time_wash() -> void:
	var overlay := Color(0.0, 0.0, 0.0, 0.0)
	match time_period:
		"night":
			overlay = Color(0.05, 0.09, 0.18, 0.3)
		"evening":
			overlay = Color(0.26, 0.14, 0.08, 0.16)
		"dawn":
			overlay = Color(0.24, 0.18, 0.1, 0.1)
	if overlay.a > 0.0:
		draw_rect(WORLD_RECT, overlay, true)


func _draw_district_tint() -> void:
	if light_level > 0.82:
		return
	for district_name in DISTRICT_RECTS.keys():
		var rect: Rect2 = DISTRICT_RECTS[district_name]
		var color := _district_color(String(district_name))
		var alpha := 0.015 + (1.0 - light_level) * 0.035
		_draw_ellipse(rect.get_center(), rect.size * Vector2(0.36, 0.22), Color(color.r, color.g, color.b, alpha))


func _draw_house_glow() -> void:
	for house_id in HOUSE_IDS:
		if not house_states.has(house_id):
			continue
		var state: Dictionary = house_states[house_id]
		var glow_boost := float(state.get("window_glow_boost", 0.0))
		var warmth := float(state.get("residual_warmth", 0.0))
		var doorstep_alpha := float(state.get("doorstep_alpha", 0.0))
		if glow_boost <= 0.03 and warmth <= 0.03 and doorstep_alpha <= 0.03:
			continue
		var row := WorldLayout.interactable_by_id(house_id)
		if row.is_empty():
			continue
		var door := Vector2(float(row.get("x", 0.0)), float(row.get("y", 0.0)))
		var color := _house_color(house_id)
		var pulse := 0.92 + sin(time_passed * 1.6 + door.x * 0.01) * 0.06
		if glow_boost > 0.03:
			_draw_ellipse(door + Vector2(0.0, -26.0), Vector2(44.0, 18.0), Color(color.r, color.g, color.b, (0.03 + glow_boost * 0.18) * pulse))
		if warmth > 0.03:
			_draw_ellipse(door + Vector2(0.0, 18.0), Vector2(66.0, 22.0), Color(color.r, color.g, color.b, 0.02 + warmth * 0.12))
		if doorstep_alpha > 0.03:
			_draw_ellipse(door + Vector2(18.0, 24.0), Vector2(42.0, 14.0), Color(color.r, color.g, color.b, doorstep_alpha * 0.08))


func _draw_sky_glow() -> void:
	var sky_alpha := 0.0
	var sky_color := Color(0.44, 0.55, 0.86, 0.0)
	match time_period:
		"night":
			sky_alpha = 0.16
			sky_color = Color(0.28, 0.4, 0.72, sky_alpha)
		"evening":
			sky_alpha = 0.12
			sky_color = Color(0.9, 0.52, 0.26, sky_alpha)
		"dawn":
			sky_alpha = 0.1
			sky_color = Color(0.94, 0.72, 0.44, sky_alpha)
	if sky_alpha <= 0.0:
		return
	_draw_ellipse(Vector2(WORLD_RECT.size.x * 0.5, WORLD_RECT.size.y * 0.08), Vector2(WORLD_RECT.size.x * 0.62, WORLD_RECT.size.y * 0.22), sky_color)


func _draw_ground_falloff() -> void:
	var alpha := 0.0
	match time_period:
		"night":
			alpha = 0.14
		"evening":
			alpha = 0.08
		"dawn":
			alpha = 0.05
	if alpha <= 0.0:
		return
	_draw_ellipse(Vector2(WORLD_RECT.size.x * 0.5, WORLD_RECT.size.y * 0.84), Vector2(WORLD_RECT.size.x * 0.7, WORLD_RECT.size.y * 0.28), Color(0.03, 0.03, 0.05, alpha))


func _draw_lantern_pools() -> void:
	if light_level > 0.78:
		return
	for house_id in HOUSE_IDS:
		var row := WorldLayout.interactable_by_id(house_id)
		if row.is_empty():
			continue
		var door := Vector2(float(row.get("x", 0.0)), float(row.get("y", 0.0)))
		var strength := clampf((0.82 - light_level) * 0.28, 0.0, 0.18)
		var color := _house_color(house_id)
		_draw_ellipse(door + Vector2(0.0, 30.0), Vector2(92.0, 26.0), Color(color.r, color.g * 0.92, color.b * 0.84, strength))


func _district_color(district_name: String) -> Color:
	match district_name:
		"港口":
			return Color(0.72, 0.88, 0.96, 1.0)
		"工厂区":
			return Color(0.92, 0.52, 0.24, 1.0)
		"交易所":
			return Color(0.98, 0.84, 0.5, 1.0)
		_:
			return Color(0.86, 0.68, 0.42, 1.0)


func _house_color(house_id: String) -> Color:
	match house_id:
		"dock_house":
			return Color(0.76, 0.9, 0.98, 1.0)
		"factory_house":
			return Color(0.96, 0.56, 0.24, 1.0)
		"exchange_house":
			return Color(0.98, 0.84, 0.5, 1.0)
		_:
			return Color(0.94, 0.72, 0.4, 1.0)


func _draw_ellipse(center: Vector2, radii: Vector2, color_value: Color) -> void:
	var points := PackedVector2Array()
	for step in range(20):
		var angle := TAU * float(step) / 20.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color_value)
