extends Node2D
class_name WorldStructureOverlay

const WORLD_RECT := Rect2(Vector2.ZERO, Vector2(3072, 2048))
const OVERLAY_TEXTURE_PATH := "res://world_overlay_layer_3.png"

var overlay_sprite := Sprite2D.new()


func _ready() -> void:
	var texture := _load_runtime_texture(OVERLAY_TEXTURE_PATH)
	if texture == null:
		return
	overlay_sprite.centered = false
	overlay_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	overlay_sprite.texture = texture
	overlay_sprite.position = Vector2.ZERO
	overlay_sprite.z_index = 20
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
