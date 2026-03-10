extends Node2D
class_name WorldStructureOverlay

const BACKDROP_TEXTURE_PATH := "res://ditu_x4_realesrgan.png"
const WORLD_RECT := Rect2(Vector2.ZERO, Vector2(3072, 2048))
const OVERLAY_TEXTURE_PATH := "res://world_overlay_layer_3.png"
const OVERLAY_SOURCE_SCALE := 1.6
const OVERLAY_SOURCE_OFFSET := Vector2(0.0, 843.0)

var overlay_sprite := Sprite2D.new()


func _ready() -> void:
	var texture := _load_runtime_texture(OVERLAY_TEXTURE_PATH)
	var backdrop_texture := _load_runtime_texture(BACKDROP_TEXTURE_PATH)
	if texture == null:
		return
	overlay_sprite.centered = false
	overlay_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	overlay_sprite.texture = texture
	overlay_sprite.z_index = 20
	if backdrop_texture != null:
		var backdrop_scale := Vector2(
			WORLD_RECT.size.x / maxf(float(backdrop_texture.get_width()), 1.0),
			WORLD_RECT.size.y / maxf(float(backdrop_texture.get_height()), 1.0)
		)
		overlay_sprite.position = Vector2(
			OVERLAY_SOURCE_OFFSET.x * backdrop_scale.x,
			OVERLAY_SOURCE_OFFSET.y * backdrop_scale.y
		)
		overlay_sprite.scale = Vector2(
			OVERLAY_SOURCE_SCALE * backdrop_scale.x,
			OVERLAY_SOURCE_SCALE * backdrop_scale.y
		)
	else:
		overlay_sprite.position = Vector2.ZERO
		overlay_sprite.scale = Vector2(
			WORLD_RECT.size.x / maxf(float(texture.get_width()), 1.0),
			WORLD_RECT.size.y / maxf(float(texture.get_height()), 1.0)
		)
	add_child(overlay_sprite)


func _load_runtime_texture(path: String) -> Texture2D:
	var image := Image.new()
	var global_path := ProjectSettings.globalize_path(path)
	if image.load(global_path) == OK:
		return ImageTexture.create_from_image(image)
	var imported := load(path)
	if imported is Texture2D:
		return imported
	return null
