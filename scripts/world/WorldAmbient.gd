extends Node2D
class_name WorldAmbient

const WorldLayout = preload("res://scripts/world/WorldLayout.gd")
const REDRAW_INTERVAL := 0.08
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
	_draw_water_motion()
	_draw_fountain_ripples()
	_draw_street_lamps()


func _draw_time_wash() -> void:
	var overlay := Color(0.0, 0.0, 0.0, 0.0)
	match time_period:
		"night":
			overlay = Color(0.04, 0.08, 0.16, 0.34)
		"evening":
			overlay = Color(0.22, 0.14, 0.08, 0.16)
		"dawn":
			overlay = Color(0.26, 0.19, 0.1, 0.1)
	if overlay.a > 0.0:
		draw_rect(WORLD_RECT, overlay, true)


func _draw_district_tint() -> void:
	if light_level > 0.84:
		return
	for district_name in DISTRICT_RECTS.keys():
		var rect: Rect2 = DISTRICT_RECTS[district_name]
		var color := _district_color(String(district_name))
		var alpha := 0.014 + (1.0 - light_level) * 0.03
		_draw_ellipse(rect.get_center(), rect.size * Vector2(0.36, 0.24), Color(color.r, color.g, color.b, alpha))


func _draw_house_glow() -> void:
	for house_id in HOUSE_IDS:
		var door := WorldLayout.house_door_for_id(house_id)
		var color := _house_color(house_id)
		var state: Dictionary = house_states.get(house_id, {})
		var glow_boost := float(state.get("window_glow_boost", 0.0))
		var warmth := float(state.get("residual_warmth", 0.0))
		var night_factor := clampf((0.82 - light_level) * 1.35, 0.0, 1.0)
		if glow_boost > 0.03 or night_factor > 0.08:
			var pulse := 0.92 + sin(time_passed * 1.6 + door.x * 0.01) * 0.06
			_draw_ellipse(door + Vector2(0.0, -32.0), Vector2(46.0, 18.0), Color(color.r, color.g, color.b, (0.025 + glow_boost * 0.18 + night_factor * 0.08) * pulse))
		if warmth > 0.03:
			_draw_ellipse(door + Vector2(0.0, 18.0), Vector2(64.0, 20.0), Color(color.r, color.g, color.b, 0.02 + warmth * 0.12))


func _draw_water_motion() -> void:
	for area in WorldLayout.water_areas():
		var rect: Rect2 = area.get("rect", Rect2())
		var flow: Vector2 = area.get("flow", Vector2.RIGHT)
		var strength := float(area.get("strength", 1.0))
		var band_alpha := 0.06 + (1.0 - light_level) * 0.02
		draw_rect(rect, Color(0.72, 0.9, 1.0, 0.03 + band_alpha * 0.28), true)
		for index in range(18):
			var phase := time_passed * (52.0 + strength * 10.0) + float(index) * 21.0
			var x := rect.position.x + fposmod(phase * flow.x * 0.8 + float(index) * 34.0, maxf(rect.size.x - 34.0, 1.0))
			var y := rect.position.y + 12.0 + fposmod(abs(sin(phase * 0.03 + float(index))) * rect.size.y, maxf(rect.size.y - 24.0, 1.0))
			var width := 20.0 + strength * 12.0 + fposmod(float(index) * 7.0, 12.0)
			draw_line(
				Vector2(x, y),
				Vector2(x + width, y + flow.y * 6.0),
				Color(0.92, 0.98, 1.0, band_alpha),
				2.0
			)
		for index in range(9):
			var foam_phase := time_passed * (31.0 + strength * 8.0) + float(index) * 17.0
			var fx := rect.position.x + fposmod(foam_phase * 0.9 + float(index) * 54.0, maxf(rect.size.x - 18.0, 1.0))
			var fy := rect.position.y + 10.0 + fposmod(foam_phase * 0.22 + float(index) * 27.0, maxf(rect.size.y - 18.0, 1.0))
			draw_circle(Vector2(fx, fy), 2.2 + sin(foam_phase * 0.04) * 0.8, Color(0.96, 0.99, 1.0, 0.08))


func _draw_fountain_ripples() -> void:
	for item in WorldLayout.fountain_points():
		var center: Vector2 = item.get("pos", Vector2.ZERO)
		var radius := float(item.get("radius", 52.0))
		var pulse := 0.5 + sin(time_passed * 2.8) * 0.08
		for ring in range(3):
			var ring_radius := radius * (0.34 + float(ring) * 0.18) + fposmod(time_passed * (18.0 + float(ring) * 4.0), 18.0)
			draw_arc(center, ring_radius, 0.0, TAU, 40, Color(0.88, 0.97, 1.0, 0.1 * pulse), 2.0)
		draw_circle(center + Vector2(0.0, -8.0 + sin(time_passed * 6.0) * 2.0), 3.6, Color(0.92, 0.99, 1.0, 0.32))


func _draw_street_lamps() -> void:
	if light_level > 0.8 and time_period == "day":
		return
	var lamp_alpha := clampf((0.84 - light_level) * 0.42, 0.0, 0.24)
	if lamp_alpha <= 0.0:
		return
	for point in WorldLayout.street_lamps():
		_draw_ellipse(point + Vector2(0.0, 18.0), Vector2(90.0, 28.0), Color(0.98, 0.87, 0.56, lamp_alpha))
		_draw_ellipse(point + Vector2(0.0, 2.0), Vector2(36.0, 46.0), Color(0.98, 0.84, 0.46, lamp_alpha * 0.46))
		draw_circle(point, 5.0, Color(1.0, 0.9, 0.64, min(0.8, lamp_alpha * 4.2)))


func _draw_sky_glow() -> void:
	var sky_alpha := 0.0
	var sky_color := Color(0.44, 0.55, 0.86, 0.0)
	match time_period:
		"night":
			sky_alpha = 0.16
			sky_color = Color(0.24, 0.36, 0.68, sky_alpha)
		"evening":
			sky_alpha = 0.12
			sky_color = Color(0.86, 0.52, 0.24, sky_alpha)
		"dawn":
			sky_alpha = 0.1
			sky_color = Color(0.92, 0.72, 0.44, sky_alpha)
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
	_draw_ellipse(Vector2(WORLD_RECT.size.x * 0.5, WORLD_RECT.size.y * 0.84), Vector2(WORLD_RECT.size.x * 0.72, WORLD_RECT.size.y * 0.28), Color(0.03, 0.03, 0.05, alpha))


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
	for step in range(24):
		var angle := TAU * float(step) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color_value)
