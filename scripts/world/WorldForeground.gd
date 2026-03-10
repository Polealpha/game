extends Node2D
class_name WorldForeground

const WorldLayout = preload("res://scripts/world/WorldLayout.gd")
const REDRAW_INTERVAL := 0.25
const WORLD_RECT := WorldLayout.WORLD_RECT
const HOUSE_IDS := ["slum_house", "dock_house", "factory_house", "exchange_house"]
const STRUCTURE_OVERLAY_TEXTURE_PATH := "res://world_overlay_layer_3_display.png"

var pulse_time := 0.0
var time_period := "day"
var light_level := 1.0
var house_states: Dictionary = {}
var redraw_accumulator := 0.0
var structure_overlay_sprite := Sprite2D.new()


func _ready() -> void:
	var overlay_texture := _load_runtime_texture(STRUCTURE_OVERLAY_TEXTURE_PATH)
	if overlay_texture == null:
		return
	structure_overlay_sprite.centered = false
	structure_overlay_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	structure_overlay_sprite.texture = overlay_texture
	structure_overlay_sprite.position = Vector2.ZERO
	structure_overlay_sprite.z_index = 12
	structure_overlay_sprite.scale = Vector2(
		WORLD_RECT.size.x / maxf(float(overlay_texture.get_width()), 1.0),
		WORLD_RECT.size.y / maxf(float(overlay_texture.get_height()), 1.0)
	)
	add_child(structure_overlay_sprite)


func _process(delta: float) -> void:
	pulse_time += delta
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
	_draw_house_thresholds()
	_draw_interaction_beacons()
	_draw_vignette()


func _load_runtime_texture(path: String) -> Texture2D:
	var image := Image.new()
	var global_path := ProjectSettings.globalize_path(path)
	if image.load(global_path) == OK:
		return ImageTexture.create_from_image(image)
	var imported := load(path)
	if imported is Texture2D:
		return imported
	return null


func _draw_house_thresholds() -> void:
	for house_id in HOUSE_IDS:
		if not house_states.has(house_id):
			continue
		var state: Dictionary = house_states[house_id]
		var warmth := float(state.get("residual_warmth", 0.0))
		var doorstep_alpha := float(state.get("doorstep_alpha", 0.0))
		if warmth <= 0.03 and doorstep_alpha <= 0.03:
			continue
		var row := WorldLayout.interactable_by_id(house_id)
		if row.is_empty():
			continue
		var door := Vector2(float(row.get("x", 0.0)), float(row.get("y", 0.0)))
		var color := _house_color(house_id)
		if warmth > 0.03:
			_draw_ellipse(door + Vector2(0.0, 18.0), Vector2(56.0, 18.0), Color(color.r, color.g, color.b, 0.04 + warmth * 0.11))
		if doorstep_alpha > 0.03:
			_draw_footprints(door + Vector2(-18.0, 20.0), doorstep_alpha, color)


func _draw_interaction_beacons() -> void:
	var alpha := clampf((1.0 - light_level) * 0.05, 0.0, 0.05)
	if alpha <= 0.0:
		return
	for interactable_id in ["exchange_board", "dock_labor", "bridge_notice", "market_whisper", "charity_board"]:
		var row := WorldLayout.interactable_by_id(interactable_id)
		if row.is_empty():
			continue
		var center := Vector2(float(row.get("x", 0.0)), float(row.get("y", 0.0)))
		_draw_ellipse(center + Vector2(0.0, 14.0), Vector2(36.0, 10.0), Color(1.0, 0.88, 0.56, alpha))


func _draw_vignette() -> void:
	draw_rect(Rect2(0.0, 0.0, WORLD_RECT.size.x, 18.0), Color(0, 0, 0, 0.03), true)
	draw_rect(Rect2(0.0, WORLD_RECT.size.y - 18.0, WORLD_RECT.size.x, 18.0), Color(0, 0, 0, 0.025), true)
	draw_rect(Rect2(0.0, 0.0, 14.0, WORLD_RECT.size.y), Color(0, 0, 0, 0.02), true)
	draw_rect(Rect2(WORLD_RECT.size.x - 14.0, 0.0, 14.0, WORLD_RECT.size.y), Color(0, 0, 0, 0.02), true)


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


func _draw_footprints(origin: Vector2, alpha: float, color_value: Color) -> void:
	for index in range(3):
		var step_center := origin + Vector2(float(index) * 12.0, float(index % 2) * 5.0)
		_draw_ellipse(step_center, Vector2(6.0, 4.0), Color(color_value.r * 0.5, color_value.g * 0.44, color_value.b * 0.38, alpha * 0.22))


func _draw_ellipse(center: Vector2, radii: Vector2, color_value: Color) -> void:
	var points := PackedVector2Array()
	for step in range(18):
		var angle := TAU * float(step) / 18.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color_value)
