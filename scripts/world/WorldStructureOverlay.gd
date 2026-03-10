extends Node2D
class_name WorldStructureOverlay

const WORLD_RECT := Rect2(Vector2.ZERO, Vector2(3072, 2048))
const OVERLAY_TEXTURE_PATH := "res://world_overlay_layer_3.png"
const TILE_SIZE := 96
const ALPHA_THRESHOLD := 0.08


func _ready() -> void:
	_build_overlay_pieces()


func _build_overlay_pieces() -> void:
	var image := _load_runtime_image(OVERLAY_TEXTURE_PATH)
	if image == null:
		return
	var shared_texture := ImageTexture.create_from_image(image)
	var scale_x := WORLD_RECT.size.x / maxf(float(image.get_width()), 1.0)
	var scale_y := WORLD_RECT.size.y / maxf(float(image.get_height()), 1.0)
	for tile_y in range(0, image.get_height(), TILE_SIZE):
		for tile_x in range(0, image.get_width(), TILE_SIZE):
			var tile_rect := Rect2i(
				tile_x,
				tile_y,
				min(TILE_SIZE, image.get_width() - tile_x),
				min(TILE_SIZE, image.get_height() - tile_y)
			)
			var used_rect := _tile_used_rect(image, tile_rect)
			if used_rect.size.x <= 0 or used_rect.size.y <= 0:
				continue
			_add_overlay_piece(shared_texture, used_rect, scale_x, scale_y)


func _add_overlay_piece(shared_texture: Texture2D, used_rect: Rect2i, scale_x: float, scale_y: float) -> void:
	var anchor := Node2D.new()
	anchor.y_sort_enabled = false
	anchor.position = Vector2(
		float(used_rect.position.x) * scale_x,
		float(used_rect.end.y) * scale_y
	)
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture = shared_texture
	sprite.region_enabled = true
	sprite.region_rect = Rect2(used_rect.position, used_rect.size)
	sprite.position = Vector2(0.0, -float(used_rect.size.y) * scale_y)
	sprite.scale = Vector2(scale_x, scale_y)
	anchor.add_child(sprite)
	add_child(anchor)


func _tile_used_rect(image: Image, tile_rect: Rect2i) -> Rect2i:
	var min_x := tile_rect.end.x
	var min_y := tile_rect.end.y
	var max_x := tile_rect.position.x - 1
	var max_y := tile_rect.position.y - 1
	for y in range(tile_rect.position.y, tile_rect.end.y):
		for x in range(tile_rect.position.x, tile_rect.end.x):
			var color := image.get_pixel(x, y)
			if color.a < ALPHA_THRESHOLD:
				continue
			min_x = min(min_x, x)
			min_y = min(min_y, y)
			max_x = max(max_x, x)
			max_y = max(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _load_runtime_image(path: String) -> Image:
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(path)) == OK:
		return image
	var texture := load(path)
	if texture is Texture2D:
		return texture.get_image()
	return null
