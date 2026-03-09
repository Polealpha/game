extends Node2D
class_name WorldBackdrop

const WorldLayout = preload("res://scripts/world/WorldLayout.gd")
const BACKGROUND_TEXTURE_PATH := "res://ditu_8k_realesrgan.png"
const ROAD_OVERLAY_TEXTURE_PATH := WorldLayout.ROAD_MASK_TEXTURE_PATH
const WORLD_RECT := WorldLayout.WORLD_RECT
const ROAD_OVERLAY_RECT := WorldLayout.ROAD_MASK_WORLD_RECT

var district_states: Dictionary = {}
var time_period := "day"
var light_level := 1.0
var background_sprite := Sprite2D.new()
var road_overlay_sprite := Sprite2D.new()


func _ready() -> void:
	var texture := _load_runtime_texture(BACKGROUND_TEXTURE_PATH)
	background_sprite.centered = false
	background_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background_sprite.texture = texture
	background_sprite.position = Vector2.ZERO
	if texture != null:
		background_sprite.scale = Vector2(
			WORLD_RECT.size.x / maxf(float(texture.get_width()), 1.0),
			WORLD_RECT.size.y / maxf(float(texture.get_height()), 1.0)
		)
	add_child(background_sprite)

	var road_texture := _load_runtime_texture(ROAD_OVERLAY_TEXTURE_PATH)
	road_overlay_sprite.centered = false
	road_overlay_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	road_overlay_sprite.texture = road_texture
	road_overlay_sprite.position = ROAD_OVERLAY_RECT.position
	if road_texture != null:
		road_overlay_sprite.scale = Vector2(
			ROAD_OVERLAY_RECT.size.x / maxf(float(road_texture.get_width()), 1.0),
			ROAD_OVERLAY_RECT.size.y / maxf(float(road_texture.get_height()), 1.0)
		)
	add_child(road_overlay_sprite)


func set_district_states(rows: Array) -> void:
	district_states.clear()
	for row in rows:
		district_states[str(row.get("name", ""))] = str(row.get("state", "normal"))


func set_time_of_day(period: String, level: float) -> void:
	time_period = period
	light_level = clampf(level, 0.2, 1.0)


func _load_runtime_texture(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(path)) != OK:
		return null
	return ImageTexture.create_from_image(image)
